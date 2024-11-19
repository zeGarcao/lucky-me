// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract IsDrawFinalized_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenCurrentOpenDrawIdBelow3() {
        _;
    }

    modifier whenCurrentOpenDrawIdAtOrAbove3() {
        skip(DRAW_DURATION * 2);
        _;
    }

    modifier whenDrawOlderThanPrevious() {
        drawId = drawManager.getCurrentOpenDrawId() - 2;
        _;
    }

    modifier whenDrawNotOlderThanPrevious() {
        drawId = drawManager.getCurrentOpenDrawId();
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_IsDrawFinalized_NoFinalizedDraws() public whenCurrentOpenDrawIdBelow3 {
        assertFalse(drawManager.isDrawFinalized(drawId));
    }

    function test_IsDrawFinalized_NotOlderEnough()
        public
        whenCurrentOpenDrawIdAtOrAbove3
        whenDrawNotOlderThanPrevious
    {
        assertFalse(drawManager.isDrawFinalized(drawId));
    }

    function test_IsDrawFinalized_OlderEnough() public whenCurrentOpenDrawIdAtOrAbove3 whenDrawOlderThanPrevious {
        assertTrue(drawManager.isDrawFinalized(drawId));
    }
}
