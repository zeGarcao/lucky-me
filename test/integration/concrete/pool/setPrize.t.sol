// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Integration_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";
import {DRAW_AWARD_DRAW__DRAW_NOT_CLOSED} from "@lucky-me/utils/Errors.sol";
import {RequestStatus} from "@lucky-me/utils/Enums.sol";

contract SetPrize_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    uint24 constant POOL_FEE = 3000;
    uint256 slippage;
    uint256 drawId;

    function setUp() public override {
        Pool_Integration_Shared_Test.setUp();

        // Bob deposit's into pool
        vm.prank(bob);
        pool.deposit(100_000e6);

        // Skip draw duration and fake yield generation
        skip(DRAW_DURATION);
        aavePool.updateYield(address(usdc), address(pool), 500e6);

        vm.startPrank(keeper);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenDrawIsNotClosed() {
        drawId = drawManager.getCurrentOpenDrawId();
        _;
    }

    modifier whenDrawIsClosed() {
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        _;
    }

    modifier whenThereIsRemainingAmount() {
        slippage = 100;
        _;
    }

    modifier whenThereIsNotRemainingAmount() {
        slippage = 0;
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_DrawNotClosed() public whenDrawIsNotClosed {
        // Expect to revert with `DRAW_AWARD_DRAW__DRAW_NOT_CLOSED` error
        vm.expectRevert(DRAW_AWARD_DRAW__DRAW_NOT_CLOSED.selector);
        pool.setPrize(drawId, POOL_FEE, slippage);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_SetPrize_NoRemainingAmount() public whenDrawIsClosed whenThereIsNotRemainingAmount {
        // Get balances before setting prize
        uint256 requestCost = drawManager.getRandomnessRequestCost();
        uint256 usdcAmountIn = _getUsdcAmountIn(requestCost, POOL_FEE, slippage);
        uint256 aaveUsdcBalanceBefore = usdc.balanceOf(address(aavePool));
        uint256 aUsdcTotalSupplyBefore = aUsdc.balanceOf(address(pool));
        uint256 vrfWrapperLinkBalanceBefore = link.balanceOf(address(vrfWrapper));

        // Set prize
        pool.setPrize(drawId, POOL_FEE, slippage);

        // Asserting that funds were withdrawn from Aave
        assertEq(usdc.balanceOf(address(aavePool)), aaveUsdcBalanceBefore - usdcAmountIn);
        // Asserting that pool's receipt tokens were burned
        assertEq(aUsdc.totalSupply(), aUsdcTotalSupplyBefore - usdcAmountIn);
        // Asserting that payment was done to the Chainlink VRF wrapper contract
        assertEq(link.balanceOf(address(vrfWrapper)), vrfWrapperLinkBalanceBefore + requestCost);
        // Asserting that randomness request id was stored
        uint256 reqId = drawManager.drawToRequestId(drawId);
        assertEq(reqId, vrfWrapper.lastRequestId());
        // Asserting that randomness request state was updated
        assertEq(uint256(drawManager.getRequest(reqId).status), uint256(RequestStatus.PENDING));
    }

    function test_SetPrize_RemainingAmount() public whenDrawIsClosed whenThereIsRemainingAmount {
        // Get balances before setting prize
        uint256 requestCost = drawManager.getRandomnessRequestCost();
        uint256 usdcAmountIn = _getUsdcAmountIn(requestCost, POOL_FEE, slippage);
        uint256 remainingAmount = usdcAmountIn - _getUsdcAmountIn(requestCost, POOL_FEE, 0);
        uint256 aaveUsdcBalanceBefore = usdc.balanceOf(address(aavePool));
        uint256 aUsdcTotalSupplyBefore = aUsdc.balanceOf(address(pool));
        uint256 vrfWrapperLinkBalanceBefore = link.balanceOf(address(vrfWrapper));

        // Set prize
        pool.setPrize(drawId, POOL_FEE, slippage);

        // Asserting that funds were withdrawn from Aave
        assertEq(usdc.balanceOf(address(aavePool)), (aaveUsdcBalanceBefore - usdcAmountIn) + remainingAmount);
        // Asserting that pool's receipt tokens were burned
        assertEq(aUsdc.totalSupply(), (aUsdcTotalSupplyBefore - usdcAmountIn) + remainingAmount);
        // Asserting that payment was done to the Chainlink VRF wrapper contract
        assertEq(link.balanceOf(address(vrfWrapper)), vrfWrapperLinkBalanceBefore + requestCost);
        // Asserting that randomness request id was stored
        uint256 reqId = drawManager.drawToRequestId(drawId);
        assertEq(reqId, vrfWrapper.lastRequestId());
        // Asserting that randomness request state was updated
        assertEq(uint256(drawManager.getRequest(reqId).status), uint256(RequestStatus.PENDING));
    }
}
