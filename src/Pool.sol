// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@lucky-me/interfaces/IPool.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";
import {
    POOL_DEPOSIT__INVALID_AMOUNT,
    POOL_WITHDRAW__INVALID_AMOUNT,
    POOL_WITHDRAW__INVALID_BALANCE,
    POOL_INIT__INVALID_ADDRESS
} from "@lucky-me/utils/Errors.sol";
import {Deposited, Withdrawn} from "@lucky-me/utils/Events.sol";
import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";

// TODO documentation
contract Pool is IPool {
    /// @notice Instance of TwabController responsible for managing balances.
    TwabController public immutable TWAB_CONTROLLER;
    /// @notice Instance of Aave pool where the funds are put to work.
    IAavePool public immutable AAVE_POOL;
    /// @notice Instance of USDC token
    IERC20 public immutable USDC;

    /* ===================== Constructor ===================== */

    // TODO documentation
    constructor(address _usdcAddress, address _aavePoolAddress, uint256 _startTime) {
        require(_usdcAddress != address(0) && _aavePoolAddress != address(0), POOL_INIT__INVALID_ADDRESS());

        AAVE_POOL = IAavePool(_aavePoolAddress);
        USDC = IERC20(_usdcAddress);
        TWAB_CONTROLLER = new TwabController(_startTime);
    }

    /* ===================== Public & External Functions ===================== */

    /// @inheritdoc IPool
    function deposit(uint256 _amount) external {
        // Revert if deposited amount is lower than the minimum deposit amount.
        require(_amount >= MIN_DEPOSIT, POOL_DEPOSIT__INVALID_AMOUNT());

        // Increases the user balance in TwabController
        uint256 newBalance = TWAB_CONTROLLER.increaseBalance(msg.sender, _amount);

        // Transfers the USDC amount from the user to the pool.
        USDC.transferFrom(msg.sender, address(this), _amount);

        // Approves and supplies all the USDC held by the pool to Aave.
        uint256 poolBalance = USDC.balanceOf(address(this));
        USDC.approve(address(AAVE_POOL), poolBalance);
        AAVE_POOL.supply(address(USDC), poolBalance, address(this), 0);

        emit Deposited(msg.sender, _amount, newBalance, block.timestamp);
    }

    /// @inheritdoc IPool
    function withdraw(uint256 _amount) external {
        // Revert if withdrawal amount is zero.
        require(_amount != 0, POOL_WITHDRAW__INVALID_AMOUNT());

        // Decreases the user balance in TwabController.
        uint256 newBalance = TWAB_CONTROLLER.decreaseBalance(msg.sender, _amount);
        // Reverts if the user remaining balance is lower than the minimum deposit amount, zero excluded.
        require(newBalance >= MIN_DEPOSIT || newBalance == 0, POOL_WITHDRAW__INVALID_BALANCE());

        // Withdraws USDC from Aave and sends it back to the user.
        AAVE_POOL.withdraw(address(USDC), _amount, msg.sender);

        emit Withdrawn(msg.sender, _amount, newBalance, block.timestamp);
    }
}
