// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

/* ===================================== POOL ERRORS ==================================== */

/// @notice Raised when an invalid USDC address is passed to the pool constructor.
error POOL_INIT__INVALID_USDC_ADDRESS();
/// @notice Raised when an invalid Aave pool address is passed to the pool constructor.
error POOL_INIT__INVALID_AAVE_POOL_ADDRESS();
/// @notice Raised when an invalid aUSDC address is passed to the pool constructor.
error POOL_INIT__INVALID_AUSDC_ADDRESS();
/// @notice Raised when an invalid keeper address is passed to the pool constructor.
error POOL_INIT__INVALID_KEEPER_ADDRESS();
/// @notice Raised when an invalid UniswapV3 swap router address is passed to the pool constructor.
error POOL_INIT__INVALID_SWAP_ROUTER_ADDRESS();
/// @notice Raised when an invalid UniswapV3 quoter address is passed to the pool constructor.
error POOL_INIT__INVALID_QUOTER_ADDRESS();
/// @notice Raised when a user tries to deposit into the pool an amount below the minimum required.
error POOL_DEPOSIT__INVALID_AMOUNT();
/// @notice Raised when a user tries to withdraw zero USDC from the pool.
error POOL_WITHDRAW__INVALID_AMOUNT();
/// @notice Raised when the user's remaining balance is invalid after a withdrawal.
error POOL_WITHDRAW__INVALID_BALANCE();
/// @notice Raised when trying to set up a prize for a not closed draw.
error POOL_PRIZE_SETUP__DRAW_NOT_CLOSED();
/// @notice Raised when there is no sufficient funds to cover randomness request cost.
error POOL_PRIZE_SETUP__NOT_ENOUGH_FUNDS();
/// @notice Raised when the prize of the draw is too small.
error POOL_PRIZE_SETUP__PRIZE_TOO_SMALL();
/// @notice Raised when an invalid keeper is given when updating keeper.
error POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS();

/* ===================================== TWAB ERRORS ==================================== */

/// @notice Raised when an invalid period offset is passed to the twab controller constructor.
error TWAB_INIT__INVALID_PERIOD_OFFSET();
/// @notice Raised when increase amount is zero.
error TWAB_INCREASE_BALANCE__INVALID_AMOUNT();
/// @notice Raised when decrease amount is zero.
error TWAB_DECREASE_BALANCE__INVALID_AMOUNT();
/// @notice Raised when a balance is decrease by an amount that exceeds the available balance.
error TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE();
/// @notice Raised when a time range start is after the end.
error TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE();
/// @notice Raised when there is no sufficient history to lookup a twab time range.
error TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY();

/* ===================================== DRAW MANAGER ERRORS ==================================== */

/// @notice Raised when an invalid start time for the genesis draw is passed to the draw manager constructor.
error DRAW_INIT__INVALID_GENESIS_START_TIME();
/// @notice Raised when trying to request a random number more than once.
error DRAW_AWARD_DRAW__REQUEST_ALREADY_SENT();
/// @notice Raised when an invalid callback gas limit is given when updating the request configuration.
error DRAW_REQUEST_CONFIG__INVALID_CALLBACK_GAS_LIMIT();
/// @notice Raised when an invalid number of request confirmations is given when updating the request configuration.
error DRAW_REQUEST_CONFIG__INVALID_REQUEST_CONFIRMATIONS();
