// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface ITwabController {
    function increaseBalance(address _account, uint256 _amount) external returns (uint256);
    function decreaseBalance(address _account, uint256 _amount) external returns (uint256);
}
