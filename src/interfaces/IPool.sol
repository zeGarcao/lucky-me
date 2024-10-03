// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IPool {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function claimPrize() external;
}
