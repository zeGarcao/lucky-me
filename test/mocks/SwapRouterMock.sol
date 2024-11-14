// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapRouterMock is ISwapRouter {
    IQuoter immutable _quoter;

    constructor(address _quoterAddress) {
        _quoter = IQuoter(_quoterAddress);
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn) {
        amountIn = _quoter.quoteExactOutputSingle(
            params.tokenIn, params.tokenOut, params.fee, params.amountOut, params.sqrtPriceLimitX96
        );
        IERC20(params.tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(params.tokenOut).transfer(params.recipient, params.amountOut);
    }
}
