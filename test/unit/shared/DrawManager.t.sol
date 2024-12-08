// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {BaseTest} from "../../BaseTest.t.sol";

abstract contract DrawManager_Unit_Shared_Test is BaseTest {
    uint256 drawId;

    function setUp() public virtual override {
        BaseTest.setUp();

        vrfWrapper.updateRequestPirce(0);
    }

    function _awardDraw(uint256 _drawId) internal {
        vm.prank(address(pool));
        drawManager.awardDraw(_drawId);

        uint256 requestId = vrfWrapper.lastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encode(requestId)));

        vrfWrapper.fulfillRandomWords(address(drawManager), requestId, randomWords);
    }
}
