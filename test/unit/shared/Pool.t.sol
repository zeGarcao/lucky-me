// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {BaseTest} from "../../BaseTest.t.sol";

abstract contract Pool_Unit_Shared_Test is BaseTest {
    uint256 withdrawAmount;
    uint256 depositAmount;

    function setUp() public virtual override {
        BaseTest.setUp();
    }
}
