// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDrawManager} from "@lucky-me/interfaces/IDrawManager.sol";
import {DRAW_CURRENT_DRAW__NO_OPEN_DRAW, DRAW__INVALID_PERIOD_OFFSET} from "@lucky-me/utils/Errors.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

// TODO documentation
contract DrawManager is IDrawManager, Ownable {
    /// @notice Time offset of the first period where the first draw starts.
    uint256 public immutable PERIOD_OFFSET;

    /* ===================== Constructor ===================== */

    // TODO documentation
    constructor(uint256 _periodOffset) Ownable(msg.sender) {
        require(_periodOffset >= block.timestamp, DRAW__INVALID_PERIOD_OFFSET());
        PERIOD_OFFSET = _periodOffset;
    }

    /* ===================== Public & External Functions ===================== */

    /// @inheritdoc IDrawManager
    function getCurrentDrawId() public view returns (uint256) {
        require(block.timestamp >= PERIOD_OFFSET, DRAW_CURRENT_DRAW__NO_OPEN_DRAW());
        return (block.timestamp - PERIOD_OFFSET) / DRAW_DURATION;
    }

    /// @inheritdoc IDrawManager
    function isDrawOpen(uint256 _drawId) public view returns (bool) {
        return _drawId == getCurrentDrawId();
    }
}
