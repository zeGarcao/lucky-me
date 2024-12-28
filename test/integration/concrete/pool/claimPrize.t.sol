// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Integration_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract ClaimPrize_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public override {
        Pool_Integration_Shared_Test.setUp();

        // Users deposit into the pool
        for (uint8 i; i < users.length; ++i) {
            vm.prank(users[i]);
            pool.deposit(1_000e6);
        }

        // Skip draw duration
        skip(DRAW_DURATION);

        // Set prize and fake yield generation
        aavePool.updateYield(address(usdc), address(pool), 500e6);
        uint256 drawId = drawManager.getCurrentOpenDrawId() - 1;
        vm.prank(keeper);
        pool.setPrize(drawId, 3000, 100);
        _fulfillRandomWords();

        // Mock scenario where Bob is an eligible winner
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

        vm.startPrank(bob);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_ClaimPrize_Winner() public {
        // Get balances before claiming
        uint256 bobBalanceBefore = twabController.getAccountBalance(bob);
        uint256 poolTotalSupplyBefore = twabController.getTotalSupply();

        // Claim prize
        uint256 prizeClaimed = pool.claimPrize();

        // Asserting that user's internal balance was updated
        assertEq(twabController.getAccountBalance(bob), bobBalanceBefore + prizeClaimed);
        // Asserting that pool's total supply was updated
        assertEq(twabController.getTotalSupply(), poolTotalSupplyBefore + prizeClaimed);

        // Asserting that the sum of all balances is equal to totalSupply
        uint256 totalSupply = twabController.getTotalSupply();
        uint256 balancesSum;

        for (uint256 i; i < users.length; ++i) {
            balancesSum += twabController.getAccountBalance(users[i]);
        }

        assertEq(balancesSum, totalSupply);
    }
}
