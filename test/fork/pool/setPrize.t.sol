// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Fork_Shared_Test} from "../shared/Pool.t.sol";
import {DRAW_DURATION, ONE_HUNDRED_PERCENT_BPS} from "@lucky-me/utils/Constants.sol";
import {DRAW_AWARD_DRAW__DRAW_NOT_CLOSED} from "@lucky-me/utils/Errors.sol";
import {RequestStatus} from "@lucky-me/utils/Enums.sol";

contract SetPrize_Fork_Concrete_Test is Pool_Fork_Shared_Test {
    uint24 constant POOL_FEE = 3000;
    uint256 drawId;
    uint256 slippage;

    function setUp() public override {
        Pool_Fork_Shared_Test.setUp();

        // Fake deposits into the pool
        vm.prank(bob);
        pool.deposit(500_000e6);

        // Skip draw duration
        skip(DRAW_DURATION);

        // Define id of the draw whose prize is to be set
        drawId = drawManager.getCurrentOpenDrawId() - 1;

        vm.startPrank(keeper);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenThereIsRemainingAmount() {
        slippage = 100;
        _;
    }

    modifier whenThereIsNotRemainingAmount() {
        slippage = 0;
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_SetPrize_NoRemainingAmount() public whenThereIsNotRemainingAmount {
        // Get balances before setting prize
        uint256 requestCost = drawManager.getRandomnessRequestCost();
        uint256 usdcAmountIn = _getUsdcAmountIn(requestCost, POOL_FEE, slippage);
        uint256 aaveUsdcBalanceBefore = USDC.balanceOf(address(A_USDC));
        uint256 poolAUsdcBalanceBefore = A_USDC.balanceOf(address(pool));

        // Set prize
        pool.setPrize(drawId, POOL_FEE, slippage);

        // Aserting that USDC was withdrawn from Aave to pay chainlink VRF service
        assertEq(USDC.balanceOf(address(A_USDC)), aaveUsdcBalanceBefore - usdcAmountIn);
        // Asserting that pool's aUSDC tokens were burned
        assertEq(A_USDC.balanceOf(address(pool)), poolAUsdcBalanceBefore - usdcAmountIn);
        // Asserting that LINK tokens were transferred out from DrawManager
        assertEq(LINK.balanceOf(address(drawManager)), 0);
    }

    function test_SetPrize_RemainingAmount() public whenThereIsRemainingAmount {
        // Get balances before setting prize
        uint256 requestCost = drawManager.getRandomnessRequestCost();
        uint256 usdcAmountIn = _getUsdcAmountIn(requestCost, POOL_FEE, slippage);
        uint256 remainingAmount = usdcAmountIn - _getUsdcAmountIn(requestCost, POOL_FEE, 0);
        uint256 aaveUsdcBalanceBefore = USDC.balanceOf(address(A_USDC));
        uint256 poolAUsdcBalanceBefore = A_USDC.balanceOf(address(pool));

        // Set prize
        pool.setPrize(drawId, POOL_FEE, slippage);

        // Aserting that USDC was withdrawn from Aave to pay chainlink VRF service
        assertEq(USDC.balanceOf(address(A_USDC)), (aaveUsdcBalanceBefore - usdcAmountIn) + remainingAmount);
        // Asserting that pool's aUSDC tokens were burned
        assertEq(A_USDC.balanceOf(address(pool)), (poolAUsdcBalanceBefore - usdcAmountIn) + remainingAmount);
        // Asserting that LINK tokens were transferred out from DrawManager
        assertEq(LINK.balanceOf(address(drawManager)), 0);
    }

    function _getUsdcAmountIn(uint256 _linkAmountOut, uint24 _poolFee, uint256 _slippage) internal returns (uint256) {
        uint256 usdcAmountIn =
            QUOTER.quoteExactOutputSingle(address(USDC), drawManager.getLinkTokenAddress(), _poolFee, _linkAmountOut, 0);

        return (usdcAmountIn * (ONE_HUNDRED_PERCENT_BPS + _slippage)) / ONE_HUNDRED_PERCENT_BPS;
    }
}
