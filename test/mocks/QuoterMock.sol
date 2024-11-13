// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";

contract QuoterMock is IQuoter {
    // TODO quote code
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn) {}
}
