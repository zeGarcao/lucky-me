// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract IsWinner_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    uint256 drawId;

    function setUp() public override {
        Pool_Unit_Shared_Test.setUp();

        vm.prank(rando);
        pool.deposit(200e6);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenUserHasZeroBalance() {
        skip(DRAW_DURATION);
        _;
    }

    modifier whenUserHasNonZeroBalance() {
        vm.prank(bob);
        pool.deposit(1_000e6);

        skip(DRAW_DURATION);
        _;
    }

    modifier whenDrawIsOpen() {
        drawId = drawManager.getCurrentOpenDrawId();
        _;
    }

    modifier whenDrawIsNotOpen() {
        _;
    }

    modifier whenDrawIsClosed() {
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        _;
    }

    modifier whenDrawIsNotClosed() {
        aUsdc.mint(address(pool), 500e6);
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        vm.prank(keeper);
        pool.setPrize(drawId, 3000, 100);
        _fulfillRandomWords();
        _;
    }

    modifier whenUserPrnModPoolTwabGreaterOrEqualWinningZone() {
        // Mock calls to set the desired scenario
        (uint256 startTime, uint256 endTime) = drawManager.getDrawPeriod(drawId);
        vm.mockCall(
            address(twabController),
            abi.encodeWithSelector(twabController.getTwabBetween.selector, bob, startTime, endTime),
            abi.encode(50e6)
        );
        vm.mockCall(
            address(twabController),
            abi.encodeWithSelector(twabController.getTotalSupplyTwabBetween.selector, startTime, endTime),
            abi.encode(390e6)
        );
        _;
    }

    modifier whenUserPrnModPoolTwabLowerThanWinningZone() {
        // Mock calls to set the desired scenario
        (uint256 startTime, uint256 endTime) = drawManager.getDrawPeriod(drawId);
        vm.mockCall(
            address(twabController),
            abi.encodeWithSelector(twabController.getTwabBetween.selector, bob, startTime, endTime),
            abi.encode(960e6)
        );
        vm.mockCall(
            address(twabController),
            abi.encodeWithSelector(twabController.getTotalSupplyTwabBetween.selector, startTime, endTime),
            abi.encode(1320e6)
        );
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_IsWinner_ZeroBalance() public whenUserHasZeroBalance {
        // Checking if Bob is the winner.
        bool isWinner = pool.isWinner(drawId, bob);

        // Asserting that Bob is not the winner since he has no balance.
        assertFalse(isWinner);
    }

    function test_IsWinner_OpenDraw() public whenUserHasNonZeroBalance whenDrawIsOpen {
        // Checking if Bob is the winner.
        bool isWinner = pool.isWinner(drawId, bob);

        // Asserting that Bob is not the winner since draw is still open
        assertFalse(isWinner);
    }

    function test_IsWinner_ClosedDraw() public whenUserHasNonZeroBalance whenDrawIsNotOpen whenDrawIsClosed {
        // Checking if Bob is the winner.
        bool isWinner = pool.isWinner(drawId, bob);

        // Asserting that Bob is not the winner since draw is still closed
        assertFalse(isWinner);
    }

    function test_IsWinner_NotWinner()
        public
        whenUserHasNonZeroBalance
        whenDrawIsNotOpen
        whenDrawIsNotClosed
        whenUserPrnModPoolTwabGreaterOrEqualWinningZone
    {
        // Checking if Bob is the winner.
        bool isWinner = pool.isWinner(drawId, bob);

        // Asserting that Bob is not the winner since his zone not below winning zone
        assertFalse(isWinner);
    }

    function test_IsWinner_Winner()
        public
        whenUserHasNonZeroBalance
        whenDrawIsNotOpen
        whenDrawIsNotClosed
        whenUserPrnModPoolTwabLowerThanWinningZone
    {
        // Checking if Bob is the winner.
        bool isWinner = pool.isWinner(drawId, bob);

        // Asserting that Bob is not the winner since his zone below winning zone
        assertTrue(isWinner);
    }
}
