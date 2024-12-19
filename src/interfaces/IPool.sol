// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {DrawManager} from "@lucky-me/DrawManager.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";
import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";
import {Prize} from "@lucky-me/utils/Structs.sol";

// TODO documentation
interface IPool {
    /**
     * @notice Deposits USDC into the pool.
     * @param _amount USDC amount to be deposited.
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice Withdraws USDC from the pool.
     * @param _amount USDC amount to be withdrawn.
     */
    function withdraw(uint256 _amount) external;

    /**
     * @notice Updates the address of the keeper.
     * @dev Must only be called by the owner.
     * @param _keeperAddress Address of the new keeper.
     */
    function updateKeeper(address _keeperAddress) external;

    /**
     * @notice Updates the luck factor list.
     * @dev Must only be called by the owner.
     * @param _luckFactorArr New luck factor list.
     */
    function updateLuckFactor(uint256[] calldata _luckFactorArr) external;

    /**
     * @notice Sets up the weekly prize of a draw.
     *         1. Computes the generated yield since the begining of the draw.
     *         2. Takes a share of the yield to swap it for LINK to cover randomness generation costs from Chainlink.
     *         3. Award the draw with its random number.
     * @dev Must only be called by the keeper.
     * @param _drawId Id of the draw for which to define the prize.
     * @param _poolFee Fee of the UniswapV3 LINK/USDC pool.
     * @param _slippage Amount of slippage for the swap.
     */
    function setPrize(uint256 _drawId, uint24 _poolFee, uint256 _slippage) external;

    /**
     * @notice Handles the prize claiming process for the previous awarded draw.
     * @return prizeAmount Prize amount received
     */
    function claimPrize() external returns (uint256 prizeAmount);

    /**
     * @notice Checks if a user is eligible to win the prize for a specific draw.
     * @param _drawId Id of the draw.
     * @param _user Address of the user.
     * @return Flag indicating if the user is eligible or not.
     */
    function isWinner(uint256 _drawId, address _user) external view returns (bool);

    /**
     * @notice Retrieves the address of the keeper.
     * @return Address of the keeper.
     */
    function keeper() external view returns (address);

    /**
     * @notice Retrieves if a user claimed the prize of a specific draw id.
     * @param _drawId Id of the draw.
     * @param _user Address of the user.
     * @return Flag indicating if user already claimed the prize or not.
     */
    function claimed(uint256 _drawId, address _user) external view returns (bool);

    /**
     * @notice Retrieves the prize data structure of a specific draw id.
     * @param _drawId Id of the draw.
     * @return Prize data of the draw.
     */
    function getDrawPrize(uint256 _drawId) external view returns (Prize memory);

    /**
     * @notice Retrieves the luck factor list.
     * @return Luck factor list.
     */
    function getLuckFactor() external view returns (uint256[] memory);

    /**
     * @notice Retrives the TwabController instance.
     * @return Instance of TwabController
     */
    function TWAB_CONTROLLER() external view returns (TwabController);

    /**
     * @notice Retrives the DrawManager instance.
     * @return Instance of DrawManager
     */
    function DRAW_MANAGER() external view returns (DrawManager);

    /**
     * @notice Retrieves the UniswapV3 swap router instance wrapped by ISwapRouter interface.
     * @return Instance of UniswapV3 swap router wrapped by ISwapRouter interface.
     */
    function SWAP_ROUTER() external view returns (ISwapRouter);

    /**
     * @notice Retrieves the Aave pool instance wrapped by IAavePool interface.
     * @return Instance of Aave pool wrapped by IAavePool interface.
     */
    function AAVE_POOL() external view returns (IAavePool);

    /**
     * @notice Retrieves the UniswapV3 quoter instance wrapped by IQuoter interface.
     * @return Instance of UniswapV3 quoter wrapped by IQuoter interface.
     */
    function QUOTER() external view returns (IQuoter);

    /**
     * @notice Retrieves the aUSDC token instance.
     * @return Instance of aUSDC token.
     */
    function USDC() external view returns (IERC20);

    /**
     * @notice Retrieves the USDC token instance.
     * @return Instance of USDC token.
     */
    function A_USDC() external view returns (IERC20);
}
