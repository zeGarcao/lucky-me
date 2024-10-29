// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface ITwabController {
    function increaseBalance(address _account, uint256 _amount) external returns (uint256);
    function decreaseBalance(address _account, uint256 _amount) external returns (uint256);
    function getTwabBetween(address _account, uint256 _startTime, uint256 _endTime) external view returns (uint256);
}
