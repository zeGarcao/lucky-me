// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IDrawManager} from "@lucky-me/interfaces/IDrawManager.sol";
import {DRAW_INIT__INVALID_GENESIS_START_TIME} from "@lucky-me/utils/Errors.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract DrawManager is IDrawManager {
    uint256 public immutable GENESIS_START_TIME;

    constructor(uint256 _genesisStartTime) {
        require(_genesisStartTime >= block.timestamp, DRAW_INIT__INVALID_GENESIS_START_TIME());

        GENESIS_START_TIME = _genesisStartTime;
    }

    function getCurrentOpenDrawId() public view returns (uint256) {
        if (block.timestamp < GENESIS_START_TIME) return 0;
        return (block.timestamp - GENESIS_START_TIME) / DRAW_DURATION;
    }

    function isDrawOpen(uint256 _drawId) public view returns (bool) {
        return _drawId == getCurrentOpenDrawId();
    }
}
