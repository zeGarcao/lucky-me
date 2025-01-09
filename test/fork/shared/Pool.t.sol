// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {console} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";

// contract Pool_Fork_Shared_Test is BaseTest {
abstract contract Pool_Fork_Shared_Test is BaseTest {
    function setUp() public virtual override {
        BaseTest.setUp();
    }

    // function testDummy() public {
    //     console.log(USDC.balanceOf(owner));
    // }
}
