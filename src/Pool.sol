// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IPool} from "./interfaces/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pool is IPool {
    using SafeERC20 for IERC20;

    uint256 public constant MIN_DEPOSIT = 10e6;
    uint256 public immutable PERIOD_OFFSET;
    uint256 public immutable PERIOD_LENGTH;
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    struct Observation {
        uint256 cumulativeBalance;
        uint256 balance;
        uint256 timestamp;
    }

    struct Account {
        uint256 balance;
        uint256 nextObservationIndex;
        uint256 cardinality;
        Observation[17520] observations;
    }

    error INVALID_AMOUNT();

    mapping(address => Account) public accounts;

    constructor(uint256 _periodOffset, uint256 _periodLength) {
        PERIOD_OFFSET = _periodOffset;
        PERIOD_LENGTH = _periodLength;
    }

    function deposit(uint256 _amount) external {
        /**
         * Checks:
         *     - check min deposit
         * Effects:
         *     - register observation
         *     - update account details
         * Interactions:
         *     - transfer the tokens to this contract
         *     - supply to Aave
         * Events:
         *     - emit BalanceIncreased event
         */
        require(_amount >= MIN_DEPOSIT, INVALID_AMOUNT());

        Account storage account = accounts[msg.sender];
        account.balance += _amount;

        uint256 currentPeriod = (block.timestamp - PERIOD_OFFSET) / PERIOD_LENGTH;
    }

    function withdraw(uint256 _amount) external {}

    function claimPrize() external {}
}
