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
    POOL_INIT__INVALID_LUCK_FACTOR,
    POOL_DEPOSIT__INVALID_AMOUNT,
    POOL_WITHDRAW__INVALID_AMOUNT,
    POOL_WITHDRAW__INVALID_BALANCE,
    POOL_SET_PRIZE__NOT_ENOUGH_FUNDS,
    POOL_SET_PRIZE__PRIZE_TOO_SMALL,
    POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS,
    POOL_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR,
    POOL_CLAIM_PRIZE__PRIZE_NOT_CLAIMABLE,
    POOL_CLAIM_PRIZE__ALREADY_CLAIMED,
    POOL_CLAIM_PRIZE__MAX_CLAIMS_REACHED,
    POOL_CLAIM_PRIZE__NOT_ELIGIBLE
} from "@lucky-me/utils/Errors.sol";
import {
    Deposited, Withdrawn, PrizeSet, KeeperUpdated, PrizeClaimed, LuckFactorUpdated
} from "@lucky-me/utils/Events.sol";
import {
    MIN_DEPOSIT,
    OWNER_ROLE,
    KEEPER_ROLE,
    MIN_PRIZE,
    ONE_HUNDRED_PERCENT_BPS,
    MAX_CLAIMS
} from "@lucky-me/utils/Constants.sol";
import {UniformRandomNumber} from "@lucky-me/libraries/UniformRandomNumber.sol";
import {Prize} from "@lucky-me/utils/Structs.sol";

/**
 * @title Lucky Me Pool
 * @author José Garção
 * @notice The Pool contract is the main entry point of the system, responsible for:
 *  - Deposits and withdrawals
 *  - Core functionality updates
 *  - Prize claims
 */
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

    /// @notice Mapping that tracks prize of each draw id.
    mapping(uint256 => Prize) private _prizes;
    /// @notice List of luck factors.
    uint256[] private _luckFactor;

    /// @notice Mapping that tracks claim status by user for each draw id.
    mapping(uint256 => mapping(address => bool)) public claimed;
    /// @notice Address of the off-chain keeper responsible for setting up prizes.
    address public keeper;

    /* ===================== Constructor ===================== */

    /**
     * @notice Pool's constructor.
     * @param _usdcAddress Address of USDC token.
     * @param _aavePoolAddress Address of Aave pool.
     * @param _aUsdcAddress Address of aUSDC token.
     * @param _keeperAddress Address of the protocol's keeper.
     * @param _vrfWrapperAddress Address of Chainlink's VRF wrapper contract.
     * @param _swapRouterAddress Address of Uniswap V3's swap router contract.
     * @param _quoterAddress Address of Uniswap V3's quoter contract.
     * @param _startTime Start timestamp of the first draw.
     * @param _luckFactorArr List of luck values for computing winner eligibility.
     */
    constructor(
        address _usdcAddress,
        address _aavePoolAddress,
        address _aUsdcAddress,
        address _keeperAddress,
        address _vrfWrapperAddress,
        address _swapRouterAddress,
        address _quoterAddress,
        uint256 _startTime,
        uint256[] memory _luckFactorArr
    ) {
        require(_usdcAddress != address(0), POOL_INIT__INVALID_USDC_ADDRESS());
        require(_aavePoolAddress != address(0), POOL_INIT__INVALID_AAVE_POOL_ADDRESS());
        require(_aUsdcAddress != address(0), POOL_INIT__INVALID_AUSDC_ADDRESS());
        require(_keeperAddress != address(0), POOL_INIT__INVALID_KEEPER_ADDRESS());
        require(_swapRouterAddress != address(0), POOL_INIT__INVALID_SWAP_ROUTER_ADDRESS());
        require(_quoterAddress != address(0), POOL_INIT__INVALID_QUOTER_ADDRESS());
        require(_luckFactorArr.length != 0, POOL_INIT__INVALID_LUCK_FACTOR());

        USDC = IERC20(_usdcAddress);
        AAVE_POOL = IAavePool(_aavePoolAddress);
        A_USDC = IERC20(_aUsdcAddress);
        SWAP_ROUTER = ISwapRouter(_swapRouterAddress);
        QUOTER = IQuoter(_quoterAddress);

        TWAB_CONTROLLER = new TwabController(_startTime);
        DRAW_MANAGER = new DrawManager(_startTime, _vrfWrapperAddress, msg.sender);

        keeper = _keeperAddress;
        _luckFactor = _luckFactorArr;

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
    function updateLuckFactor(uint256[] calldata _luckFactorArr) external onlyRole(OWNER_ROLE) {
        // Reverts if new luck factor list is empty.
        require(_luckFactorArr.length != 0, POOL_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR());

        // Updates luck factor list.
        uint256[] memory oldLuckFactor = _luckFactor;
        _luckFactor = _luckFactorArr;

        emit LuckFactorUpdated(oldLuckFactor, _luckFactorArr, block.timestamp);
    }

    /// @inheritdoc IPool
    function setPrize(uint256 _drawId, uint24 _poolFee, uint256 _slippage) external onlyRole(KEEPER_ROLE) {
        // Compute the generated yield from Aave.
        uint256 yield = A_USDC.balanceOf(address(this)) - TWAB_CONTROLLER.getTotalSupply();
        // Get the cost of the randomness request.
        uint256 randomnessRequestCost = DRAW_MANAGER.getRandomnessRequestCost();
        // Compute the USDC amount needed to swap for LINK to cover the cost of the randomness request.
        uint256 usdcAmountIn = _getUsdcAmountIn(randomnessRequestCost, _poolFee, _slippage);

        // Ensure there are enough funds to cover the cost of the randomness request.
        require(yield > usdcAmountIn, POOL_SET_PRIZE__NOT_ENOUGH_FUNDS());

        // Compute the prize for the draw.
        uint256 prize = (yield - usdcAmountIn) / MAX_CLAIMS;
        // Ensure there is a sufficient prize amount.
        require(prize >= MIN_PRIZE, POOL_SET_PRIZE__PRIZE_TOO_SMALL());

        // Withdraw USDC from Aave and decrease total supply in twab controller.
        AAVE_POOL.withdraw(address(USDC), usdcAmountIn, address(this));

        // Swap USDC for LINK and call DrawManager to award the draw.
        _swapUsdcForLink(_poolFee, randomnessRequestCost, usdcAmountIn);
        DRAW_MANAGER.awardDraw(_drawId);

        // Supply to Aave and increase total supply in twab controller if there is a remaining balance.
        uint256 remainingBalance = USDC.balanceOf(address(this));
        if (remainingBalance > 0) {
            USDC.approve(address(AAVE_POOL), remainingBalance);
            AAVE_POOL.supply(address(USDC), remainingBalance, address(this), 0);
        }

        // Sets the prize amount for the draw.
        _prizes[_drawId].amount = prize;

        emit PrizeSet(_drawId, prize, block.timestamp);
    }

    /// @inheritdoc IPool
    function claimPrize() external returns (uint256 prizeAmount) {
        // Retrieves the previous draw id and its corresponding prize.
        uint256 drawId = DRAW_MANAGER.getCurrentOpenDrawId() - 1;
        Prize storage prize = _prizes[drawId];

        // Reverts if draw is not awarded yet.
        require(DRAW_MANAGER.isDrawAwarded(drawId), POOL_CLAIM_PRIZE__PRIZE_NOT_CLAIMABLE());
        // Reverts if user is not eligible to claim the prize.
        require(isWinner(drawId, msg.sender), POOL_CLAIM_PRIZE__NOT_ELIGIBLE());
        // Reverts if the user already claimed the prize.
        require(!claimed[drawId][msg.sender], POOL_CLAIM_PRIZE__ALREADY_CLAIMED());
        // Reverts if maximum number of claims was already reached.
        require(prize.claims < MAX_CLAIMS, POOL_CLAIM_PRIZE__MAX_CLAIMS_REACHED());

        // Records that the user claimed the prize and increases the number of claims.
        claimed[drawId][msg.sender] = true;
        prize.claims += 1;
        prizeAmount = prize.amount;

        // Credits the prize to the user's account.
        uint256 newBalance = TWAB_CONTROLLER.increaseBalance(msg.sender, prizeAmount);

        emit PrizeClaimed(drawId, msg.sender, prizeAmount, newBalance, block.timestamp);
    }

    /// @inheritdoc IPool
    function isWinner(uint256 _drawId, address _user) public view returns (bool) {
        // Not eligible if user has no balance.
        if (TWAB_CONTROLLER.getAccountBalance(_user) == 0) return false;

        // No winner if draw is open or closed.
        if (DRAW_MANAGER.isDrawOpen(_drawId) || DRAW_MANAGER.isDrawClosed(_drawId)) return false;

        // Retrieves the start and end times of the draw.
        (uint256 startTime, uint256 endTime) = DRAW_MANAGER.getDrawPeriod(_drawId);
        // Retrieves the random number of the draw.
        uint256 drawRandomNumber = DRAW_MANAGER.getDrawRandomNumber(_drawId);

        // Retrieves the user and pool twabs.
        uint256 poolTwab = TWAB_CONTROLLER.getTotalSupplyTwabBetween(startTime, endTime);
        uint256 userTwab = TWAB_CONTROLLER.getTwabBetween(_user, startTime, endTime);

        // Computes the user pseudo random number.
        uint256 userPRN = uint256(keccak256(abi.encode(_drawId, drawRandomNumber, _user)));
        // Retrieves the user luck factor.
        uint256 luckFactor = _luckFactor[UniformRandomNumber.uniform(userPRN, _luckFactor.length)];
        // Computes the winning zone.
        uint256 winningZone = (userTwab * luckFactor) / ONE_HUNDRED_PERCENT_BPS;
        // Computes user zone.
        uint256 userZone = UniformRandomNumber.uniform(userPRN, poolTwab);

        return userZone < winningZone;
    }

    /// @inheritdoc IPool
    function getDrawPrize(uint256 _drawId) public view returns (Prize memory) {
        return _prizes[_drawId];
    }

    /// @inheritdoc IPool
    function getLuckFactor() public view returns (uint256[] memory) {
        return _luckFactor;
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
