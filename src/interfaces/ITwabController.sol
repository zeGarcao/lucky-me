// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {AccountDetails} from "@lucky-me/utils/Structs.sol";

// TODO documentation
interface ITwabController {
    /**
     * @notice Increases a user's account balance and records the corresponding observation.
     * @dev This function must only be called by the owner.
     * @param _account User address pointing to their account.
     * @param _amount Amount by which the user's account balance will increase.
     * @return New user account balance.
     */
    function increaseBalance(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Decreases a user's account balance and records the corresponding observation.
     * @dev This function must only be called by the owner.
     * @param _account User address pointing to their account.
     * @param _amount Amount by which the user's account balance will decrease.
     * @return New user account balance.
     */
    function decreaseBalance(address _account, uint256 _amount) external returns (uint256);

    /**
     * @notice Increases total supply account balance and records the corresponding observation.
     * @dev This function must only be called by the owner.
     * @param _amount Amount by which the total supply account balance will increase.
     * @return New total supply account balance.
     */
    function increaseTotalSupply(uint256 _amount) external returns (uint256);

    /**
     * @notice Decreases total supply account balance and records the corresponding observation.
     * @dev This function must only be called by the owner.
     * @param _amount Amount by which the total supply account balance will decrease.
     * @return New total supply account balance.
     */
    function decreaseTotalSupply(uint256 _amount) external returns (uint256);

    /**
     * @notice Gets a user's time-weighted average balance (TWAB) between two timestamps.
     * @dev If timestamps in the range aren't exact matches of observations, balance is extrapolated using the previous observation.
     * @param _account User address pointing to their account.
     * @param _startTime The start of the time range.
     * @param _endTime The end of the time range.
     * @return User TWAB for the time range.
     */
    function getTwabBetween(address _account, uint256 _startTime, uint256 _endTime) external view returns (uint256);

    /**
     * @notice Gets a user's account details.
     * @param _account User address pointing to their account.
     * @return User's account details.
     */
    function getAccount(address _account) external view returns (AccountDetails memory);

    /**
     * @notice Gets the total supply account details.
     * @return Total supply account details.
     */
    function getTotalSupplyAccount() external view returns (AccountDetails memory);

    /**
     * @notice Gets the total supply balance.
     * @return Total supply balance.
     */
    function getTotalSupply() external view returns (uint256);

    /**
     * @notice Gets the time offset of the first period.
     * @return Time offset of the first period.
     */
    function PERIOD_OFFSET() external view returns (uint256);
}
