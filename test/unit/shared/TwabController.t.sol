// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {BaseTest} from "../../BaseTest.t.sol";

abstract contract TwabController_Unit_Shared_Test is BaseTest {
    uint256 increaseAmount;
    uint256 decreaseAmount;
    uint256 skipLength;

    function setUp() public virtual override {
        BaseTest.setUp();
    }
}
