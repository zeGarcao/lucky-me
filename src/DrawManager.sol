// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDrawManager} from "@lucky-me/interfaces/IDrawManager.sol";

contract DrawManager is IDrawManager, Ownable {
    constructor() Ownable(msg.sender) {}
}
