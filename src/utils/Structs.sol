// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MAX_CARDINALITY} from "@lucky-me/utils/Constants.sol";
import {RequestStatus} from "@lucky-me/utils/Enums.sol";

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

/**
 * @notice Data structure to store information of each draw.
 * @param requestId Id of the randomness request associated with the draw.
 * @param claims Number of prize claims for the draw.
 * @param prize Prize assigned to the draw.
 */
struct Draw {
    uint256 requestId;
    uint256 claims;
    uint256 prize;
}

/**
 * @notice Data structure to store request information.
 * @param status Status of the request.
 * @param randomNumber Random number retrieved from the request.
 */
struct Request {
    RequestStatus status;
    uint256 randomNumber;
}

/**
 * @notice Data structure to store data related to the randomness request configuration data.
 * @param callbackGasLimit Gas limit used by the callback function.
 * @param requestConfirmations Number of request confirmations.
 */
struct RequestConfig {
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
}
