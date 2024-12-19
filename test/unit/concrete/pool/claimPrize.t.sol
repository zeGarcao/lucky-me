// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION, MAX_CLAIMS} from "@lucky-me/utils/Constants.sol";
import {
    POOL_CLAIM_PRIZE__PRIZE_NOT_CLAIMABLE,
    POOL_CLAIM_PRIZE__ALREADY_CLAIMED,
    POOL_CLAIM_PRIZE__MAX_CLAIMS_REACHED,
    POOL_CLAIM_PRIZE__NOT_ELIGIBLE
} from "@lucky-me/utils/Errors.sol";
import {PrizeClaimed} from "@lucky-me/utils/Events.sol";

contract ClaimPrize_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    function setUp() public override {
        Pool_Unit_Shared_Test.setUp();

        for (uint8 i; i < users.length; ++i) {
            vm.prank(users[i]);
            pool.deposit(1_000e6);
        }

        skip(DRAW_DURATION);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenDrawIsNotAwarded() {
        _;
    }

    modifier whenDrawIsAwarded() {
        aUsdc.mint(address(pool), 500e6);
        uint256 drawId = drawManager.getCurrentOpenDrawId() - 1;
        vm.prank(keeper);
        pool.setPrize(drawId, 3000, 100);
        _fulfillRandomWords();
        _;
    }

    modifier whenUserIsNotEligible() {
        // Mock calls to set the desired scenario
        (uint256 startTime, uint256 endTime) = drawManager.getDrawPeriod(drawManager.getCurrentOpenDrawId() - 1);
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

    modifier whenUserIsEligible() {
        (uint256 startTime, uint256 endTime) = drawManager.getDrawPeriod(drawManager.getCurrentOpenDrawId() - 1);
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

    modifier whenUserAlreadyClaimedPrize() {
        vm.prank(bob);
        pool.claimPrize();
        _;
    }

    modifier whenUserDidNotClaimedPrizeYet() {
        _;
    }

    modifier whenMaxClaimsReached() {
        vm.mockCall(
            address(twabController), abi.encodeWithSelector(twabController.getTwabBetween.selector), abi.encode(960e6)
        );
        vm.mockCall(
            address(twabController),
            abi.encodeWithSelector(twabController.getTotalSupplyTwabBetween.selector),
            abi.encode(1320e6)
        );
        vm.prank(alice);
        pool.claimPrize();
        vm.prank(carol);
        pool.claimPrize();
        vm.prank(rando);
        pool.claimPrize();
        _;
    }

    modifier whenMaxClaimsNotReached() {
        _;
    }

    modifier prankUser() {
        vm.startPrank(bob);
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_DrawNotAwarded() public whenDrawIsNotAwarded prankUser {
        vm.expectRevert(POOL_CLAIM_PRIZE__PRIZE_NOT_CLAIMABLE.selector);
        pool.claimPrize();
    }

    function test_RevertWhen_NotEligible() public whenDrawIsAwarded whenUserIsNotEligible prankUser {
        vm.expectRevert(POOL_CLAIM_PRIZE__NOT_ELIGIBLE.selector);
        pool.claimPrize();
    }

    function test_RevertWhen_AlreadyClaimed()
        public
        whenDrawIsAwarded
        whenUserIsEligible
        whenUserAlreadyClaimedPrize
        prankUser
    {
        vm.expectRevert(POOL_CLAIM_PRIZE__ALREADY_CLAIMED.selector);
        pool.claimPrize();
    }

    function test_RevertWhen_MaxClaimsReached()
        public
        whenDrawIsAwarded
        whenUserIsEligible
        whenUserDidNotClaimedPrizeYet
        whenMaxClaimsReached
        prankUser
    {
        vm.expectRevert(POOL_CLAIM_PRIZE__MAX_CLAIMS_REACHED.selector);
        pool.claimPrize();
    }

    // ==================================== HAPPY TESTS ====================================

    function test_ClaimPrize_EligibleWinner()
        public
        whenDrawIsAwarded
        whenUserIsEligible
        whenUserDidNotClaimedPrizeYet
        whenMaxClaimsNotReached
        prankUser
    {
        uint256 drawId = drawManager.getCurrentOpenDrawId() - 1;
        uint256 prize = pool.getDrawPrize(drawId).amount;
        uint256 bobBalanceBefore = twabController.getAccount(bob).balance;

        // Expect call to `twabController` to credit prize
        vm.expectCall(address(twabController), abi.encodeCall(twabController.creditBalance, (bob, prize)));
        // Expect the `PrizeClaimed` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit PrizeClaimed(drawId, bob, prize, bobBalanceBefore + prize, block.timestamp);

        // Bob claims the prize
        pool.claimPrize();

        // Asserting that bob's claim status was updated
        bool bobClaimed = pool.claimed(drawId, bob);
        assertTrue(bobClaimed);
        // Asserting that number of prize claims was updated
        uint256 prizeClaims = pool.getDrawPrize(drawId).claims;
        assertEq(prizeClaims, 1);
    }
}
