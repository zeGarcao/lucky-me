// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

/* ===================================== POOL ERRORS ==================================== */
/// @notice Emitted when an invalid address for USDC or Aave contracts is passed to the pool constructor.
error POOL_INIT__INVALID_ADDRESS();
/// @notice Emitted when a user tries to deposit into the pool an amount below the minimum required.
error POOL_DEPOSIT__INVALID_AMOUNT();
/// @notice Emitted when a user tries to withdraw zero USDC from the pool.
error POOL_WITHDRAW__INVALID_AMOUNT();
/// @notice Emitted when the user's remaining balance is invalid after a withdrawal.
error POOL_WITHDRAW__INVALID_BALANCE();

/* ===================================== TWAB ERRORS ==================================== */
/// @notice Emitted when an invalid period offset is passed to the twab controller constructor.
error TWAB_INIT__INVALID_PERIOD_OFFSET();
/// @notice Emitted when increase amount is zero.
error TWAB_INCREASE_BALANCE__INVALID_AMOUNT();
/// @notice Emitted when decrease amount is zero.
error TWAB_DECREASE_BALANCE__INVALID_AMOUNT();
/// @notice Emitted when a balance is decrease by an amount that exceeds the available balance.
error TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE();
/// @notice Emitted when a time range start is after the end.
error TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE();
/// @notice Emitted when there is no sufficient history to lookup a twab time range.
error TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY();

/* ===================================== DRAW MANAGER ERRORS ==================================== */
/// @notice Emitted when an invalid period offset is passed to the draw manager.
error DRAW__INVALID_PERIOD_OFFSET();
/// @notice Emitted when checking for the current draw id and none has started yet.
error DRAW_CURRENT_DRAW__NO_OPEN_DRAW();
