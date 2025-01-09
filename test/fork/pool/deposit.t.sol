// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {Pool_Fork_Shared_Test} from "../shared/Pool.t.sol";

contract Deposit_Fork_Concrete_Test is Pool_Fork_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenDepositAmountAboveMin() {
        depositAmount = MIN_DEPOSIT;
        vm.startPrank(bob);
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_Deposit_ValidDeposit() public whenDepositAmountAboveMin {
        // Get balances before pool deposit
        uint256 bobUsdcBalanceBefore = USDC.balanceOf(bob);
        uint256 aaveUsdcBalanceBefore = USDC.balanceOf(address(A_USDC));
        uint256 poolAUsdcBalanceBefore = A_USDC.balanceOf(address(pool));

        // Deposit into the pool
        pool.deposit(depositAmount);

        // Asserting that bob's balance was updated
        assertEq(USDC.balanceOf(bob), bobUsdcBalanceBefore - depositAmount);
        // Asserting that bob's funds were supplied to Aave
        // assertEq(USDC.balanceOf(address(A_USDC)), aaveUsdcBalanceBefore + depositAmount);
        // Asserting that aUsdc was minted to the pool
        // assertEq(A_USDC.balanceOf(address(pool)), poolAUsdcBalanceBefore + poolAUsdcBalanceBefore);
    }
}
