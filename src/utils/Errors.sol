// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

// ===================================== POOL ERRORS ====================================
error POOL_INIT__INVALID_ADDRESS();
error POOL_DEPOSIT__INVALID_AMOUNT();
error POOL_WITHDRAW__INVALID_AMOUNT();
error POOL_WITHDRAW__INVALID_BALANCE();

// ===================================== TWAB ERRORS ====================================
error TWAB_INIT__INVALID_PERIOD_OFFSET();
error TWAB_INCREASE_BALANCE__INVALID_AMOUNT();
error TWAB_DECREASE_BALANCE__INVALID_AMOUNT();
error TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE();
error TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE();
error TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY();
