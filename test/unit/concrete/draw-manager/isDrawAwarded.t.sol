// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract IsDrawAwarded_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenCurrentOpenDrawIdBelow2() {
        _;
    }

    modifier whenCurrentOpenDrawIdAtOrAbove2() {
        skip(DRAW_DURATION);
        _;
    }

    modifier whenDrawIdNotPrevious() {
        drawId = drawManager.getCurrentOpenDrawId();
        _;
    }

    modifier whenDrawIdIsPrevious() {
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        _;
    }

    modifier whenRandomnessRequestIsFulfilled() {
        _awardDraw(drawId);
        _;
    }

    modifier whenRandomnessRequestIsNotFulfilled() {
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_IsDrawAwarded_NoAwardedDraws() public view whenCurrentOpenDrawIdBelow2 {
        assertFalse(drawManager.isDrawAwarded(drawId));
    }

    function test_IsDrawAwarded_NotPrevious() public whenCurrentOpenDrawIdAtOrAbove2 whenDrawIdNotPrevious {
        assertFalse(drawManager.isDrawAwarded(drawId));
    }

    function test_IsDrawAwarded_PreviousWithoutRandomnessFulfilled()
        public
        whenCurrentOpenDrawIdAtOrAbove2
        whenDrawIdIsPrevious
        whenRandomnessRequestIsNotFulfilled
    {
        assertFalse(drawManager.isDrawAwarded(drawId));
    }

    function test_IsDrawAwarded_PreviousWithRandomnessFulfilled()
        public
        whenCurrentOpenDrawIdAtOrAbove2
        whenDrawIdIsPrevious
        whenRandomnessRequestIsFulfilled
    {
        assertTrue(drawManager.isDrawAwarded(drawId));
    }
}
