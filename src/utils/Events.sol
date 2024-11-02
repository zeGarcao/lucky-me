// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Observation} from "@lucky-me/utils/Structs.sol";

event Deposited(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

event Withdrawn(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

event BalanceIncreased(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

event BalanceDecreased(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

event ObservationRecorded(address indexed account, Observation observation, bool isNew);
