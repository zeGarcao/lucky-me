// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract IsDrawClosed_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    uint256 drawId;
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
        vrfWrapper.updateRequestPirce(0);
        vm.prank(address(pool));
        drawManager.awardDraw(drawId, 100e6);
        uint256 requestId = vrfWrapper.lastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encode(requestId)));
        vrfWrapper.fulfillRandomWords(address(drawManager), requestId, randomWords);
        _;
    }

    modifier whenRandomnessRequestIsNotFulfilled() {
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_IsDrawClosed_NoClosedDraws() public whenCurrentOpenDrawIdBelow2 {
        assertFalse(drawManager.isDrawClosed(drawId));
    }

    function test_IsDrawClosed_NotPrevious() public whenCurrentOpenDrawIdAtOrAbove2 whenDrawIdNotPrevious {
        assertFalse(drawManager.isDrawClosed(drawId));
    }

    function test_IsDrawClosed_PreviousWithRandomnessFulfilled()
        public
        whenCurrentOpenDrawIdAtOrAbove2
        whenDrawIdIsPrevious
        whenRandomnessRequestIsFulfilled
    {
        assertFalse(drawManager.isDrawClosed(drawId));
    }

    function test_IsDrawClosed_PreviousWithoutRandomnessFulfilled()
        public
        whenCurrentOpenDrawIdAtOrAbove2
        whenDrawIdIsPrevious
        whenRandomnessRequestIsNotFulfilled
    {
        assertTrue(drawManager.isDrawClosed(drawId));
    }
}
