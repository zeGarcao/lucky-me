// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IPool} from "./interfaces/IPool.sol";
import {TwabController} from "./TwabController.sol";
import {IAavePool} from "./interfaces/IAavePool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pool is IPool {
    error DEPOSIT__INVALID_AMOUNT();
    error WITHDRAW__INVALID_AMOUNT();
    error WITHDRAW__INVALID_BALANCE();

    event Deposited(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);
    event Withdrawn(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

    uint256 public constant MIN_DEPOSIT = 10e6;
    IAavePool public constant AAVE_POOL = IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    TwabController public immutable twabController;

    constructor(uint256 _startTime) {
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
