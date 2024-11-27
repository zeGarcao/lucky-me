// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";
import {DRAW_AWARD_DRAW__DRAW_NOT_CLOSED} from "@lucky-me/utils/Errors.sol";
import {RandomnessRequestSent} from "@lucky-me/utils/Events.sol";
import {RequestConfig, Request} from "@lucky-me/utils/Structs.sol";
import {VRFV2PlusClient} from "@chainlink/vrf/dev/libraries/VRFV2PlusClient.sol";
import {RequestStatus} from "@lucky-me/utils/Enums.sol";

contract AwardDraw_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerDoesNotHaveOwnerRole() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerHasOwnerRole() {
        vm.startPrank(address(pool));
        _;
    }

    modifier whenDrawIsNotClosed() {
        drawId = drawManager.getCurrentOpenDrawId();
        _;
    }

    modifier whenDrawIsClosed() {
        skip(DRAW_DURATION);
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_NotOwner() public whenCallerDoesNotHaveOwnerRole {
        // Expect revert since caller does not have `OWNER_ROLE` role.
        vm.expectRevert();
        drawManager.awardDraw(drawId);
    }

    function test_RevertWhen_DrawNotClosed() public whenCallerHasOwnerRole whenDrawIsNotClosed {
        // Expect revert with `DRAW_AWARD_DRAW__DRAW_NOT_CLOSED` error.
        vm.expectRevert(DRAW_AWARD_DRAW__DRAW_NOT_CLOSED.selector);
        drawManager.awardDraw(drawId);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_AwardDraw_RequestRandomness() public whenCallerHasOwnerRole whenDrawIsClosed {
        // Expect call to link token to request randomness.
        address reqTo = address(vrfWrapper);
        uint256 reqPrice = drawManager.getRandomnessRequestCost();
        RequestConfig memory reqConfig = drawManager.getRequestConfig();
        bytes memory reqData = abi.encode(
            reqConfig.callbackGasLimit,
            reqConfig.requestConfirmations,
            1,
            VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        );
        vm.expectCall(address(link), abi.encodeCall(link.transferAndCall, (reqTo, reqPrice, reqData)));

        // Expect the `RandomnessRequestSent` event to be emitted.
        vm.expectEmit(true, true, true, true);
        emit RandomnessRequestSent(vrfWrapper.lastRequestId(), drawId, block.timestamp);

        // Awards draw.
        drawManager.awardDraw(drawId);

        // Asserting that the correct request id was assigned to the draw id.
        uint256 expectedRequestId = vrfWrapper.lastRequestId();
        assertEq(drawManager.drawToRequestId(drawId), expectedRequestId);

        // Asserting that the request status was updated to `PENDING`.
        Request memory request = drawManager.getRequest(expectedRequestId);
        assertEq(uint256(request.status), uint256(RequestStatus.PENDING));
    }
}
