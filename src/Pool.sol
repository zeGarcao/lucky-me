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

contract Pool is IPool {
    IAavePool public immutable AAVE_POOL;
    IERC20 public immutable USDC;
    TwabController public immutable twabController;

    constructor(address _usdcAddress, address _aavePoolAddress, uint256 _startTime) {
        require(_usdcAddress != address(0) && _aavePoolAddress != address(0), POOL_INIT__INVALID_ADDRESS());

        AAVE_POOL = IAavePool(_aavePoolAddress);
        USDC = IERC20(_usdcAddress);
        twabController = new TwabController(_startTime);
    }

    function deposit(uint256 _amount) external {
        require(_amount >= MIN_DEPOSIT, POOL_DEPOSIT__INVALID_AMOUNT());

        uint256 newBalance = twabController.increaseBalance(msg.sender, _amount);

        USDC.transferFrom(msg.sender, address(this), _amount);

        uint256 poolBalance = USDC.balanceOf(address(this));
        USDC.approve(address(AAVE_POOL), poolBalance);
        AAVE_POOL.supply(address(USDC), poolBalance, address(this), 0);

        emit Deposited(msg.sender, _amount, newBalance, block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        require(_amount != 0, POOL_WITHDRAW__INVALID_AMOUNT());

        uint256 newBalance = twabController.decreaseBalance(msg.sender, _amount);
        require(newBalance >= MIN_DEPOSIT || newBalance == 0, POOL_WITHDRAW__INVALID_BALANCE());

        AAVE_POOL.withdraw(address(USDC), _amount, msg.sender);

        emit Withdrawn(msg.sender, _amount, newBalance, block.timestamp);
    }
}
