// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Observation} from "@lucky-me/utils/Structs.sol";

/**
 * @notice Emitted whenever a user successfully deposited into the pool.
 * @param account Address of the user who deposited into the pool.
 * @param amount Amount that was deposited into the pool.
 * @param balance User account balance after deposit.
 * @param timestamp Timestamp when the deposit took place.
 */
event Deposited(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

/**
 * @notice Emitted whenever a user successfully withdraws from the pool.
 * @param account Address of the user who withdrew from the pool.
 * @param amount Amount that was withdrawn from the pool.
 * @param balance User account balance after withdrawal.
 * @param timestamp Timestamp when the withdrawal took place.
 */
event Withdrawn(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

/**
 * @notice Emitted whenever a user account balance is successfully increased.
 * @param account Address of the user whose account balance was increased.
 * @param amount Amount the user account balance increased by.
 * @param balance User account balance after increase.
 * @param timestamp Timestamp when the increase took place.
 */
event BalanceIncreased(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

/**
 * @notice Emitted whenever a user account balance is successfully decreased.
 * @param account Address of the user whose account balance was decreased.
 * @param amount Amount the user account balance decreased by.
 * @param balance User account balance after decrease.
 * @param timestamp Timestamp when the decrease took place.
 */
event BalanceDecreased(address indexed account, uint256 amount, uint256 balance, uint256 timestamp);

/**
 * @notice Emitted whenever an observation is recorded to the ring buffer.
 * @param account Address of the user whose observation was recorded.
 * @param observation Observation that was created or updated.
 * @param isNew Flag indicating whether the observation is new or not.
 */
event ObservationRecorded(address indexed account, Observation observation, bool isNew);
