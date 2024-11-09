// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {DrawManager} from "@lucky-me/DrawManager.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";
import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";

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
     * @notice Sets up the weekly prize of a draw.
     *         1. Computes the generated yield since the begining of the draw.
     *         2. Takes a share of the yield to swap it for LINK to cover randomness generation costs from Chainlink.
     *         3. Calls the draw manager to set up the draw for prize claiming.
     * @dev Must only be called by the keeper.
     * @param _poolFee Fee of the UniswapV3 LINK/USDC pool.
     * @param _slippage Amount of slippage for the swap.
     */
    function setUpPrize(uint24 _poolFee, uint256 _slippage) external;

    /**
     * @notice Retrieves the address of the keeper.
     * @return Address of the keeper.
     */
    function keeper() external view returns (address);

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
