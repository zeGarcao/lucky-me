// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

// Minimum amount allowed for pool deposits.
uint256 constant MIN_DEPOSIT = 10e6;
// Minimum period length for observations. When period elapses, a new observation is recorded, otherwise newest observation is updated.
uint256 constant PERIOD_LENGTH = 1 hours;
// Maximum ring buffer length for observation list. With minimum period of 1 hour, this allows for minimum two years of history.
uint256 constant MAX_CARDINALITY = 17520;
// Time duration of a draw.
uint256 constant DRAW_DURATION = 1 weeks;
