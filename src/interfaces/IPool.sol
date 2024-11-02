// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";

interface IPool {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function TWAB_CONTROLLER() external view returns (TwabController);
    function AAVE_POOL() external view returns (IAavePool);
    function USDC() external view returns (IERC20);
}
