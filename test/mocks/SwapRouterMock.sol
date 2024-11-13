// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";

contract SwapRouterMock is ISwapRouter {
    // TODO swap code
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn) {}
}
