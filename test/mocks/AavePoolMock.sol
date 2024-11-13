// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";

contract AavePoolMock is IAavePool {
    // TODO supply code
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {}

    // TODO withdraw code
    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        return 0;
    }
}
