// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";

contract IsDrawOpen_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenDrawIdEqualCurrentDrawId() {
        drawId = drawManager.getCurrentOpenDrawId();
        _;
    }

    modifier whenDrawIdDifferCurrentDrawId() {
        drawId = drawManager.getCurrentOpenDrawId() + 1;
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_IsDrawOpen_OpenDraw() public whenDrawIdEqualCurrentDrawId {
        // Assert that draw with id `drawId` is open.
        assertTrue(drawManager.isDrawOpen(drawId));
    }

    function test_IsDrawOpen_DrawNotOpen() public whenDrawIdDifferCurrentDrawId {
        // Assert that draw with id `drawId` is not open.
        assertFalse(drawManager.isDrawOpen(drawId));
    }
}
