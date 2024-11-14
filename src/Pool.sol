// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@lucky-me/interfaces/IPool.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {DrawManager} from "@lucky-me/DrawManager.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";
import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";
import {
    POOL_INIT__INVALID_USDC_ADDRESS,
    POOL_INIT__INVALID_AAVE_POOL_ADDRESS,
    POOL_INIT__INVALID_AUSDC_ADDRESS,
    POOL_INIT__INVALID_KEEPER_ADDRESS,
    POOL_INIT__INVALID_SWAP_ROUTER_ADDRESS,
    POOL_INIT__INVALID_QUOTER_ADDRESS,
    POOL_DEPOSIT__INVALID_AMOUNT,
    POOL_WITHDRAW__INVALID_AMOUNT,
    POOL_WITHDRAW__INVALID_BALANCE,
    POOL_PRIZE_SETUP__DRAW_NOT_CLOSED,
    POOL_PRIZE_SETUP__NOT_ENOUGH_FUNDS,
    POOL_PRIZE_SETUP__PRIZE_TOO_SMALL,
    POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS
} from "@lucky-me/utils/Errors.sol";
import {Deposited, Withdrawn, PrizeSetUp, KeeperUpdated} from "@lucky-me/utils/Events.sol";
import {MIN_DEPOSIT, OWNER_ROLE, KEEPER_ROLE, MIN_PRIZE, ONE_HUNDRED_PERCENT_BPS} from "@lucky-me/utils/Constants.sol";

// TODO documentation
contract Pool is IPool, AccessControl {
    /// @notice Instance of TwabController responsible for managing balances.
    TwabController public immutable TWAB_CONTROLLER;
    /// @notice Instance of DrawManager responsible for managing draws.
    DrawManager public immutable DRAW_MANAGER;
    /// @notice Instance of UniswapV3 swap router to swap USDC for LINK.
    ISwapRouter public immutable SWAP_ROUTER;
    /// @notice Instance of Aave pool where the funds are put to work.
    IAavePool public immutable AAVE_POOL;
    /// @notice Instance of UniswapV3 quoter to lookup quotes.
    IQuoter public immutable QUOTER;
    /// @notice Instance of aUSDC token.
    IERC20 public immutable A_USDC;
    /// @notice Instance of USDC token.
    IERC20 public immutable USDC;

    /// @notice Address of the off-chain keeper responsible for setting up prizes.
    address public keeper;

    /* ===================== Constructor ===================== */

    // TODO documentation
    constructor(
        address _usdcAddress,
        address _aavePoolAddress,
        address _aUsdcAddress,
        address _keeperAddress,
        address _vrfWrapperAddress,
        address _swapRouterAddress,
        address _quoterAddress,
        uint256 _startTime
    ) {
        require(_usdcAddress != address(0), POOL_INIT__INVALID_USDC_ADDRESS());
        require(_aavePoolAddress != address(0), POOL_INIT__INVALID_AAVE_POOL_ADDRESS());
        require(_aUsdcAddress != address(0), POOL_INIT__INVALID_AUSDC_ADDRESS());
        require(_keeperAddress != address(0), POOL_INIT__INVALID_KEEPER_ADDRESS());
        require(_swapRouterAddress != address(0), POOL_INIT__INVALID_SWAP_ROUTER_ADDRESS());
        require(_quoterAddress != address(0), POOL_INIT__INVALID_QUOTER_ADDRESS());

        USDC = IERC20(_usdcAddress);
        AAVE_POOL = IAavePool(_aavePoolAddress);
        A_USDC = IERC20(_aUsdcAddress);
        SWAP_ROUTER = ISwapRouter(_swapRouterAddress);
        QUOTER = IQuoter(_quoterAddress);

        TWAB_CONTROLLER = new TwabController(_startTime);
        DRAW_MANAGER = new DrawManager(_startTime, _vrfWrapperAddress);

        keeper = _keeperAddress;

        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(KEEPER_ROLE, _keeperAddress);
    }

    /* ===================== Public & External Functions ===================== */

    /// @inheritdoc IPool
    function deposit(uint256 _amount) external {
        // Revert if deposited amount is lower than the minimum deposit amount.
        require(_amount >= MIN_DEPOSIT, POOL_DEPOSIT__INVALID_AMOUNT());

        // Increases the user balance in TwabController
        uint256 newBalance = TWAB_CONTROLLER.increaseBalance(msg.sender, _amount);

        // Transfers the USDC amount from the user to the pool.
        USDC.transferFrom(msg.sender, address(this), _amount);

        // Approves and supplies all the USDC held by the pool to Aave.
        uint256 poolBalance = USDC.balanceOf(address(this));
        USDC.approve(address(AAVE_POOL), poolBalance);
        AAVE_POOL.supply(address(USDC), poolBalance, address(this), 0);

        emit Deposited(msg.sender, _amount, newBalance, block.timestamp);
    }

    /// @inheritdoc IPool
    function withdraw(uint256 _amount) external {
        // Revert if withdrawal amount is zero.
        require(_amount != 0, POOL_WITHDRAW__INVALID_AMOUNT());

        // Decreases the user balance in TwabController.
        uint256 newBalance = TWAB_CONTROLLER.decreaseBalance(msg.sender, _amount);
        // Reverts if the user remaining balance is lower than the minimum deposit amount, zero excluded.
        require(newBalance >= MIN_DEPOSIT || newBalance == 0, POOL_WITHDRAW__INVALID_BALANCE());

        // Withdraws USDC from Aave and sends it back to the user.
        AAVE_POOL.withdraw(address(USDC), _amount, msg.sender);

        emit Withdrawn(msg.sender, _amount, newBalance, block.timestamp);
    }

    /// @inheritdoc IPool
    function updateKeeper(address _keeperAddress) external onlyRole(OWNER_ROLE) {
        // Revert if address of new keeper is address zero or the same as the current keeper.
        require(_keeperAddress != address(0) && _keeperAddress != keeper, POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS());

        // Update keeper instance variable.
        address oldKeeper = keeper;
        keeper = _keeperAddress;

        // Revoke keeper role for the old keeper and grant it to the new one.
        _revokeRole(KEEPER_ROLE, oldKeeper);
        _grantRole(KEEPER_ROLE, _keeperAddress);

        emit KeeperUpdated(_keeperAddress, oldKeeper, block.timestamp);
    }

    /// @inheritdoc IPool
    function setUpPrize(uint24 _poolFee, uint256 _slippage) external onlyRole(KEEPER_ROLE) {
        // Get the id of the draw for which the prize needs to be set up.
        uint256 drawId = DRAW_MANAGER.getCurrentOpenDrawId() - 1;
        // Revert if the draw is not closed.
        require(DRAW_MANAGER.isDrawClosed(drawId), POOL_PRIZE_SETUP__DRAW_NOT_CLOSED());

        // Compute the generated yield from Aave.
        uint256 yield = A_USDC.balanceOf(address(this)) - TWAB_CONTROLLER.getTotalSupply();
        // Get the cost of the randomness request.
        uint256 randomnessRequestCost = DRAW_MANAGER.getRandomnessRequestCost();
        // Compute the USDC amount needed to swap for LINK to cover the cost of the randomness request.
        uint256 usdcAmountIn = _getUsdcAmountIn(randomnessRequestCost, _poolFee, _slippage);

        // Ensure there are enough funds to cover the cost of the randomness request.
        require(yield > usdcAmountIn, POOL_PRIZE_SETUP__NOT_ENOUGH_FUNDS());

        // Compute the prize for the draw.
        uint256 prize = yield - usdcAmountIn;
        // Ensure there is a sufficient prize amount.
        require(prize >= MIN_PRIZE, POOL_PRIZE_SETUP__PRIZE_TOO_SMALL());

        // Withdraw USDC from Aave and decrease total supply in twab controller.
        TWAB_CONTROLLER.decreaseTotalSupply(usdcAmountIn);
        AAVE_POOL.withdraw(address(USDC), usdcAmountIn, address(this));

        // Swap USDC for LINK and call DrawManager to award the draw.
        _swapUsdcForLink(_poolFee, randomnessRequestCost, usdcAmountIn);
        DRAW_MANAGER.awardDraw(drawId, prize);

        // Supply to Aave and increase total supply in twab controller if there is a remaining balance.
        uint256 remainingBalance = USDC.balanceOf(address(this));
        if (remainingBalance > 0) {
            TWAB_CONTROLLER.increaseTotalSupply(remainingBalance);
            AAVE_POOL.supply(address(USDC), remainingBalance, address(this), 0);
        }

        emit PrizeSetUp(drawId, prize, block.timestamp);
    }

    /* ===================== Internal & Private Functions ===================== */

    /**
     * @notice Swaps USDC for LINK and send it to DrawManager.
     * @param _poolFee Fee of the UniswapV3 LINK/USDC pool.
     * @param _linkAmountOut Outuput amount of LINK tokens.
     * @param _usdcAmountIn Input amount of USDC tokens.
     */
    function _swapUsdcForLink(uint24 _poolFee, uint256 _linkAmountOut, uint256 _usdcAmountIn) internal {
        // Approve the UniswapV3 swap router the necessary amount of USDC tokens.
        USDC.approve(address(SWAP_ROUTER), _usdcAmountIn);

        // Set the swap parameters.
        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(USDC),
            tokenOut: DRAW_MANAGER.getLinkTokenAddress(),
            fee: _poolFee,
            recipient: address(DRAW_MANAGER),
            deadline: block.timestamp,
            amountOut: _linkAmountOut,
            amountInMaximum: _usdcAmountIn,
            sqrtPriceLimitX96: 0
        });

        // Execute the swap.
        SWAP_ROUTER.exactOutputSingle(swapParams);
    }

    /**
     * @notice Computes how much USDC tokens are needed to receive a `_linkAmountOut` amount of LINK tokens, slippage included.
     * @param _linkAmountOut Desired output amount of LINK tokens.
     * @param _poolFee Fee of the UniswapV3 LINK/USDC pool.
     * @param _slippage Desired amount of slippage for the swap.
     * @return Required input amount of USDC tokens to receive the desired output amount of LINK tokens.
     */
    function _getUsdcAmountIn(uint256 _linkAmountOut, uint24 _poolFee, uint256 _slippage) internal returns (uint256) {
        // Fecth the necessary input amount of USDC in order to receiver back a `_linkAmountOut` output amount of LINK.
        uint256 usdcAmountIn = QUOTER.quoteExactOutputSingle(
            address(USDC), DRAW_MANAGER.getLinkTokenAddress(), _poolFee, _linkAmountOut, 0
        );

        // Apply slippage and return the necessary input amount of USDC.
        return (usdcAmountIn * (ONE_HUNDRED_PERCENT_BPS + _slippage)) / ONE_HUNDRED_PERCENT_BPS;
    }
}
