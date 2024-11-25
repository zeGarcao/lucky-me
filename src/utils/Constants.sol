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
// Minimum prize of each draw.
uint256 constant MIN_PRIZE = 100e6;
// Randomness request default configuration for callback gas limit.
uint32 constant DEFAULT_CALLBACK_GAS_LIMIT = 100000; // TODO test callback function to determine its gas cost
// Randomness request default configuration for number of request confirmations.
uint16 constant DEFAULT_REQUEST_CONFIRMATIONS = 3;
// Owner role used for access control, keccak256 of "OWNER_ROLE" string.
bytes32 constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;
// Owner role used for access control, keccak256 of "ADMIN_ROLE" string.
bytes32 constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
// Owner role used for access control, keccak256 of "KEEPER_ROLE" string.
bytes32 constant KEEPER_ROLE = 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab;
// One hundred percent in basis points.
uint256 constant ONE_HUNDRED_PERCENT_BPS = 10_000;
// Maximum number of prize claims for a draw.
uint256 constant MAX_CLAIMS = 3;
