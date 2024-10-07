// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IPool} from "./interfaces/IPool.sol";
import {TwabController} from "./TwabController.sol";
import {IAavePool} from "./interfaces/IAavePool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DEPOSIT__INVALID_AMOUNT, WITHDRAW__INVALID_AMOUNT, WITHDRAW__INVALID_BALANCE} from "./utils/Errors.sol";
import {Deposited, Withdrawn} from "./utils/Events.sol";
import {MIN_DEPOSIT} from "./utils/Constants.sol";

contract Pool is IPool {
    IAavePool public immutable AAVE_POOL;
    IERC20 public immutable USDC;
    TwabController public immutable twabController;

    constructor(address _usdcAddress, address _aavePoolAddress, uint256 _startTime) {
        // @todo check inputs
        AAVE_POOL = IAavePool(_aavePoolAddress);
        USDC = IERC20(_usdcAddress);
        twabController = new TwabController(_startTime);
    }

    function deposit(uint256 _amount) external {
        require(_amount >= MIN_DEPOSIT, DEPOSIT__INVALID_AMOUNT());

        uint256 newBalance = twabController.increaseBalance(msg.sender, _amount);

        USDC.transferFrom(msg.sender, address(this), _amount);

        uint256 poolBalance = USDC.balanceOf(address(this));
        USDC.approve(address(AAVE_POOL), poolBalance);
        AAVE_POOL.supply(address(USDC), poolBalance, address(this), 0);

        emit Deposited(msg.sender, _amount, newBalance, block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        require(_amount != 0, WITHDRAW__INVALID_AMOUNT());

        uint256 newBalance = twabController.decreaseBalance(msg.sender, _amount);
        require(newBalance >= MIN_DEPOSIT || newBalance == 0, WITHDRAW__INVALID_BALANCE());

        AAVE_POOL.withdraw(address(USDC), _amount, msg.sender);

        emit Withdrawn(msg.sender, _amount, newBalance, block.timestamp);
    }
}
