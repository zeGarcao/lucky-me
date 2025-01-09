// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Fork_Shared_Test} from "../shared/Pool.t.sol";
import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";

contract Withdraw_Fork_Concrete_Test is Pool_Fork_Shared_Test {
    function setUp() public override {
        Pool_Fork_Shared_Test.setUp();

        depositAmount = MIN_DEPOSIT;

        vm.startPrank(bob);
        pool.deposit(depositAmount);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenWithdrawAmountEqualsDepositAmount() {
        withdrawAmount = depositAmount;
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_Withdraw_ValidWithdrawal() public whenWithdrawAmountEqualsDepositAmount {
        // Get balances before withdrawal
        uint256 bobUsdcBalanceBefore = USDC.balanceOf(bob);
        uint256 aaveUsdcBalanceBefore = USDC.balanceOf(address(A_USDC));
        uint256 poolAUsdcBalanceBefore = A_USDC.balanceOf(address(pool));

        // Withdraw from the pool
        pool.withdraw(withdrawAmount);

        // Asserting that user's USDC balance was updated
        assertEq(USDC.balanceOf(bob), bobUsdcBalanceBefore + withdrawAmount);
        // Asserting that USDC was withdrawn from aave
        assertEq(USDC.balanceOf(address(A_USDC)), aaveUsdcBalanceBefore - withdrawAmount);
        // Asserting that pool's aUSDC tokens were burned
        assertEq(A_USDC.balanceOf(address(pool)), poolAUsdcBalanceBefore - withdrawAmount);
    }
}
