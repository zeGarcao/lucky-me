// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";

contract QuoterMock is IQuoter {
    // mock quote for LINK/USDC
    uint256 public constant QUOTE = 15e18;
    // pool fee of 0.3%
    uint256 public constant POOL_FEE = 3000;

    // hardcoded functionality for LINK/USDC pair
    function quoteExactOutputSingle(address, address, uint24, uint256 amountOut, uint160)
        external
        returns (uint256 amountIn)
    {
        uint256 amountInWithoutFee = (amountOut * QUOTE) / 1e18;
        uint256 feeAmount = (amountInWithoutFee * POOL_FEE) / 1_000_000;
        amountIn = (amountInWithoutFee + feeAmount) / 1e12;
    }
}
