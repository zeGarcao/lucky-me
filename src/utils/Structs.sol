// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MAX_CARDINALITY} from "@lucky-me/utils/Constants.sol";

/**
 * @notice Data structure to store observation information.
 * @param balance Balance at `timestamp`.
 * @param cumulativeBalance Cumulative time-weighted balance at `timestamp`.
 * @param timestamp Timestamp when observation was recorded.
 */
struct Observation {
    uint256 balance;
    uint256 cumulativeBalance;
    uint256 timestamp;
}

/**
 * @notice Data structure to store users' account details.
 * @param balance Current USDC balance for the account.
 * @param nextObservationIndex Next uninitialized or updatable ring buffer checkpoint storage slot.
 * @param cardinality Current total initialized ring buffer checkpoints for the account.
 * @param observations History of observations for the account.
 */
struct AccountDetails {
    uint256 balance;
    uint256 nextObservationIndex;
    uint256 cardinality;
    Observation[MAX_CARDINALITY] observations;
}
