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

/**
 * @notice Emitted whenever a randomness request is sent.
 * @param requestId Id of the request.
 * @param drawId Id of the draw.
 * @param timestamp Timestamp of the request.
 */
event RandomnessRequestSent(uint256 indexed requestId, uint256 indexed drawId, uint256 timestamp);

/**
 * @notice Emitted whenever a randomness request is fulffiled.
 * @param requestId Id of the request.
 * @param timestamp Timestamp of the fulfillment.
 */
event RandomnessRequestFulFilled(uint256 indexed requestId, uint256 timestamp);

/**
 * @notice Emitted whenever the randomness request configuration is updated.
 * @param callbackGasLimit Gas limit used by the callback.
 * @param requestConfirmations Number of request confirmations.
 * @param timestamp Timestamp of the update.
 */
event RequestConfigUpdated(uint32 callbackGasLimit, uint16 requestConfirmations, uint256 timestamp);

/**
 * @notice Emitted whenever a prize is set up for a draw.
 * @param drawId Id of the draw.
 * @param prize Prize assigned to the draw.
 * @param timestamp Timestamp of prize setup.
 */
event PrizeSetUp(uint256 indexed drawId, uint256 prize, uint256 timestamp);

/**
 * @notice Emitted whenever the keeper is updated.
 * @param newKeeper Address of the new keeper.
 * @param oldKeeper Address of the old keeper.
 * @param timestamp Timestamp of the update.
 */
event KeeperUpdated(address indexed newKeeper, address indexed oldKeeper, uint256 timestamp);

/**
 * @notice Emitted whenever total supply balance is successfully increased.
 * @param amount Amount the total supply balance increased by.
 * @param totalSupply Total supply balance after increase.
 * @param timestamp Timestamp when the increase took place.
 */
event TotalSupplyIncreased(uint256 amount, uint256 totalSupply, uint256 timestamp);

/**
 * @notice Emitted whenever total supply balance is successfully decreased.
 * @param amount Amount the total supply balance decreased by.
 * @param totalSupply Total supply balance after decrease.
 * @param timestamp Timestamp when the decrease took place.
 */
event TotalSupplyDecreased(uint256 amount, uint256 totalSupply, uint256 timestamp);

/**
 * @notice Emitted whenever luck factor list is successfully updated.
 * @param oldLuckFactor Old luck factor list.
 * @param newLuckFactor New luck factor list.
 * @param timestamp Timestamp of the updated.
 */
event LuckFactorUpdated(uint256[] oldLuckFactor, uint256[] newLuckFactor, uint256 timestamp);

/**
 * @notice Emitted whenever a prize is successfully claimed.
 * @param drawId Id of the draw.
 * @param user Address of the user.
 * @param prize Prize claimed.
 * @param timestamp Timestamp when claiming took place.
 */
event PrizeClaimed(uint256 drawId, address user, uint256 prize, uint256 timestamp);
