// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IDrawManager} from "@lucky-me/interfaces/IDrawManager.sol";
import {DRAW_INIT__INVALID_PERIOD_OFFSET} from "@lucky-me/utils/Errors.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

// TODO documentation
contract DrawManager is IDrawManager {
    /// @notice Time offset of the first period where the first draw starts.
    uint256 public immutable PERIOD_OFFSET;

    /* ===================== Constructor ===================== */

    // TODO documentation
    constructor(uint256 _periodOffset) {
        require(_periodOffset >= block.timestamp, DRAW_INIT__INVALID_PERIOD_OFFSET());

        PERIOD_OFFSET = _periodOffset;
    }

    /* ===================== Public & External Functions ===================== */

    function getCurrentOpenDrawId() public view returns (uint256) {
        if (block.timestamp < PERIOD_OFFSET) return 0;
        return (block.timestamp - PERIOD_OFFSET) / DRAW_DURATION;
    }

    function isDrawOpen(uint256 _drawId) public view returns (bool) {
        return _drawId == getCurrentOpenDrawId();
    }
}
