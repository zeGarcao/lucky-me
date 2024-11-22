// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {BaseTest} from "../../BaseTest.t.sol";
import {Observation} from "@lucky-me/utils/Structs.sol";

abstract contract TwabController_Unit_Shared_Test is BaseTest {
    Observation startObservation;
    Observation endObservation;
    uint256 startTime;
    uint256 endTime;
    uint256 increaseAmount;
    uint256 decreaseAmount;
    uint256 skipLength;

    function setUp() public virtual override {
        BaseTest.setUp();
    }
}
