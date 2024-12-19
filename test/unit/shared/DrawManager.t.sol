// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {BaseTest} from "../../BaseTest.t.sol";

abstract contract DrawManager_Unit_Shared_Test is BaseTest {
    uint256 drawId;

    function setUp() public virtual override {
        BaseTest.setUp();

        vrfWrapper.updateRequestPirce(0);
    }
}
