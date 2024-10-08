// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MAX_CARDINALITY} from "./Constants.sol";

struct Observation {
    uint256 balance;
    uint256 cumulativeBalance;
    uint256 timestamp;
}

struct AccountDetails {
    uint256 balance;
    uint256 nextObservationIndex;
    uint256 cardinality;
    Observation[MAX_CARDINALITY] observations;
}
