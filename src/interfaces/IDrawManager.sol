// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

// TODO documentation
interface IDrawManager {
    /**
     * @notice Retrieves the current open draw id.
     * @return Id of the current open draw.
     */
    function getCurrentDrawId() external view returns (uint256);

    /**
     * @notice Retrieves whether the draw with id `_drawId` is open or not.
     * @param _drawId Id of the draw.
     * @return Flag indicating whether the draw is open or not.
     */
    function isDrawOpen(uint256 _drawId) external view returns (bool);

    /**
     * @notice Gets the time offset of the first period where the first draw starts.
     * @return Time offset of the first period.
     */
    function PERIOD_OFFSET() external view returns (uint256);
}
