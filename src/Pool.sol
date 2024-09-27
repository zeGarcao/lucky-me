// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IPool} from "./interfaces/IPool.sol";

contract Pool is IPool {
    uint256 public constant MIN_DEPOSIT = 10e6;

    constructor() {}

    function deposit(uint256 _amount) external {}

    function withdraw(uint256 _amount) external {}
}
