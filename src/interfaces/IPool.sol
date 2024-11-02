// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";

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
     * @notice Retrives the TwabController instance.
     * @return Instance of TwabController
     */
    function TWAB_CONTROLLER() external view returns (TwabController);

    /**
     * @notice Retrieves the Aave pool instance wrapped by IAavePool interface.
     * @return Instance of Aave pool wrapped by IAavePool interface.
     */
    function AAVE_POOL() external view returns (IAavePool);

    /**
     * @notice Retrieves the USDC token instance.
     * @return Instance of USDC token.
     */
    function USDC() external view returns (IERC20);
}
