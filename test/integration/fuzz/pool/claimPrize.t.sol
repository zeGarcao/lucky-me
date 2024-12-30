// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Integration_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION, MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {POOL_CLAIM_PRIZE__NOT_ELIGIBLE} from "@lucky-me/utils/Errors.sol";

contract ClaimPrize_Integration_Fuzz_Test is Pool_Integration_Shared_Test {
    uint256 drawId;
    address claimer;

    function testFuzz_ClaimPrize_WinAndLose(uint256 _depositAmount, uint256 _claimer)
        public
        setUpState(_depositAmount, _claimer)
    {
        bool isWinner = pool.isWinner(drawId, claimer);

        if (isWinner) _testWin();
        else _testLose();
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier setUpState(uint256 _depositAmount, uint256 _claimer) {
        // set up deposits
        for (uint8 i; i < users.length; ++i) {
            address user = users[i];
            uint256 randValue = uint256(keccak256(abi.encode(user, i, _depositAmount)));
            uint256 userDepositAmount = _clampBetween(randValue, MIN_DEPOSIT, usdc.balanceOf(user) + 1);
            vm.prank(user);
            pool.deposit(userDepositAmount);
        }

        // skip draw duration
        skip(DRAW_DURATION);

        // set prize and award draw
        aUsdc.mint(address(pool), 500e6);
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        vm.prank(keeper);
        pool.setPrize(drawId, 3000, 100);
        _fulfillRandomWords();

        // randomly select user to claim prize
        claimer = users[_clampBetween(_claimer, 0, users.length)];
        vm.startPrank(claimer);
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function _testLose() internal {
        // Expect to revert with `POOL_CLAIM_PRIZE__NOT_ELIGIBLE` error
        vm.expectRevert(POOL_CLAIM_PRIZE__NOT_ELIGIBLE.selector);
        pool.claimPrize();
    }

    // ==================================== HAPPY TESTS ====================================

    function _testWin() internal {
        // Get balances before claiming
        uint256 claimerBalanceBefore = twabController.getAccountBalance(claimer);
        uint256 poolTotalSupplyBefore = twabController.getTotalSupply();

        // Claim prize
        uint256 prizeClaimed = pool.claimPrize();

        // Asserting that user's internal balance was updated
        assertEq(twabController.getAccountBalance(claimer), claimerBalanceBefore + prizeClaimed);
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
