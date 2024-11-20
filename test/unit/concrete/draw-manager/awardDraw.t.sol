// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION, DEFAULT_CALLBACK_GAS_LIMIT, DEFAULT_REQUEST_CONFIRMATIONS} from "@lucky-me/utils/Constants.sol";
import {DRAW_AWARD_DRAW__REQUEST_ALREADY_SENT} from "@lucky-me/utils/Errors.sol";
import {VRFV2PlusClient} from "@chainlink/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Request, Draw} from "@lucky-me/utils/Structs.sol";
import {RequestStatus} from "@lucky-me/utils/Enums.sol";
import {RandomnessRequestSent} from "@lucky-me/utils/Events.sol";

contract AwardDraw_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    uint256 constant PRIZE = 100e6;

    function setUp() public override {
        DrawManager_Unit_Shared_Test.setUp();
        skip(DRAW_DURATION);
        drawId = drawManager.getCurrentOpenDrawId() - 1;
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerIsNotOwner() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerIsOwner() {
        vm.startPrank(address(pool));
        _;
    }

    modifier whenRandomnessRequestAlreadySent() {
        drawManager.awardDraw(drawId, PRIZE);
        _;
    }

    modifier whenRandomnessRequestNotSent() {
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_NotOwner() public whenCallerIsNotOwner {
        // Expect revert since caller is not the owner.
        vm.expectRevert();
        drawManager.awardDraw(drawId, PRIZE);
    }

    function test_RevertWhen_RandomnessRequestAlreadySent() public whenCallerIsOwner whenRandomnessRequestAlreadySent {
        // Expect revert with `DRAW_AWARD_DRAW__REQUEST_ALREADY_SENT` error.
        vm.expectRevert(DRAW_AWARD_DRAW__REQUEST_ALREADY_SENT.selector);
        drawManager.awardDraw(drawId, PRIZE);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_AwardDraw_RandomnessRequest() public whenCallerIsOwner whenRandomnessRequestNotSent {
        // Expect call to `transferAndCall` function of LINK token contract to trigger the randomness request.
        address reqTo = address(drawManager.i_vrfV2PlusWrapper());
        uint256 reqPrice = drawManager.getRandomnessRequestCost();
        bytes memory reqData = abi.encode(
            DEFAULT_CALLBACK_GAS_LIMIT,
            DEFAULT_REQUEST_CONFIRMATIONS,
            1,
            VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        );
        vm.expectCall(address(link), abi.encodeCall(link.transferAndCall, (reqTo, reqPrice, reqData)));

        // Expect `RandomnessRequestSent` to be emitted.
        uint256 requestId = vrfWrapper.lastRequestId();
        vm.expectEmit(true, true, true, true);
        emit RandomnessRequestSent(requestId, drawId, block.timestamp);

        // Award the draw.
        drawManager.awardDraw(drawId, PRIZE);

        // Asserting that request status was updated to `PENDING`.
        Request memory request = drawManager.getRequest(requestId);
        assertEq(uint256(request.status), uint256(RequestStatus.PENDING));

        // Asserting that prize and request id were stored for the corresponding draw.
        Draw memory draw = drawManager.getDraw(drawId);
        assertEq(draw.prize, PRIZE);
        assertEq(draw.requestId, requestId);
    }
}
