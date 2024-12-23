// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION, MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {POOL_CLAIM_PRIZE__NOT_ELIGIBLE} from "@lucky-me/utils/Errors.sol";
import {PrizeClaimed} from "@lucky-me/utils/Events.sol";

contract ClaimPrize_Unit_Fuzz_Test is Pool_Unit_Shared_Test {
    uint256 drawId;
    address claimer;

    // Entry point
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
        uint256 prize = pool.getDrawPrize(drawId).amount;
        uint256 claimerBalanceBefore = twabController.getAccount(claimer).balance;

        // Expect call to `twabController` to credit prize
        vm.expectCall(address(twabController), abi.encodeCall(twabController.creditBalance, (claimer, prize)));
        // Expect the `PrizeClaimed` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit PrizeClaimed(drawId, claimer, prize, claimerBalanceBefore + prize, block.timestamp);

        // Claimer claims the prize
        pool.claimPrize();

        // Asserting that claimer's claim status was updated
        bool claimerClaimed = pool.claimed(drawId, claimer);
        assertTrue(claimerClaimed);
        // Asserting that number of prize claims was updated
        uint256 prizeClaims = pool.getDrawPrize(drawId).claims;
        assertEq(prizeClaims, 1);
    }
}
