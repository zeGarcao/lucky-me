// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ITwabController} from "@lucky-me/interfaces/ITwabController.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BalanceIncreased, BalanceDecreased, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {MAX_CARDINALITY, PERIOD_LENGTH} from "@lucky-me/utils/Constants.sol";
import {Observation, AccountDetails} from "@lucky-me/utils/Structs.sol";
import {
    TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE,
    TWAB_DECREASE_BALANCE__INVALID_AMOUNT,
    TWAB_INCREASE_BALANCE__INVALID_AMOUNT,
    TWAB_INIT__INVALID_PERIOD_OFFSET,
    TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE,
    TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY
} from "@lucky-me/utils/Errors.sol";

// TODO documentation
contract TwabController is ITwabController, Ownable {
    /// @notice Time offset of the first period.
    uint256 public immutable PERIOD_OFFSET;

    /// @notice Account details of total supply responsible for tracking its observations.
    AccountDetails private _totalSupplyAccount;
    /// @notice Mapping that tracks users' balances and observations.
    mapping(address => AccountDetails) private _accounts;

    /* ===================== Constructor ===================== */

    // TODO documentation
    constructor(uint256 _periodOffset) Ownable(msg.sender) {
        require(_periodOffset >= block.timestamp, TWAB_INIT__INVALID_PERIOD_OFFSET());
        PERIOD_OFFSET = _periodOffset;
    }

    /* ===================== Public & External Functions ===================== */

    /// @inheritdoc ITwabController
    function increaseBalance(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        // Reverts if increase amount is zero.
        require(_amount != 0, TWAB_INCREASE_BALANCE__INVALID_AMOUNT());

        // Increases the user's account balance.
        (uint256 newBalance, Observation memory observation, bool isNewObservation) =
            _increaseBalance(_accounts[_account], _amount);

        // Increases the total supply.
        _increaseBalance(_totalSupplyAccount, _amount);

        emit BalanceIncreased(_account, _amount, newBalance, block.timestamp);
        emit ObservationRecorded(_account, observation, isNewObservation);

        return newBalance;
    }

    /// @inheritdoc ITwabController
    function decreaseBalance(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        // Reverts if decrease amount is zero.
        require(_amount != 0, TWAB_DECREASE_BALANCE__INVALID_AMOUNT());

        // Reverts if the user has not sufficient balance.
        AccountDetails storage account = _accounts[_account];
        require(_amount <= account.balance, TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE());

        // Decreases the user's account balance.
        (uint256 newBalance, Observation memory observation, bool isNewObservation) = _decreaseBalance(account, _amount);

        // Decreases the total supply.
        _decreaseBalance(_totalSupplyAccount, _amount);

        emit BalanceDecreased(_account, _amount, newBalance, block.timestamp);
        emit ObservationRecorded(_account, observation, isNewObservation);

        return newBalance;
    }

    /// @inheritdoc ITwabController
    function getTwabBetween(address _account, uint256 _startTime, uint256 _endTime) external view returns (uint256) {
        // Reverts if start time is more recent than the end time.
        require(_startTime <= _endTime, TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE());

        AccountDetails memory account = _accounts[_account];

        // Gets the observation recorded before or at the end timestamp.
        Observation memory endObservation = _getPreviousOrAtObservation(account, _endTime);

        // Returns the balance of `endObservation` if start and end times are the same.
        if (_startTime == _endTime) return endObservation.balance;

        // Gets the observation recorded before or at the start timestamp.
        Observation memory startObservation = _getPreviousOrAtObservation(account, _startTime);

        // Extrapolate balance of `startObservation` if its timestamp does not match the start timestamp.
        if (startObservation.timestamp != _startTime) {
            startObservation = _calculateTemporaryObservation(startObservation, _startTime);
        }

        // Extrapolate balance of `endObservation` if its timestamp does not match the end timestamp.
        if (endObservation.timestamp != _endTime) {
            endObservation = _calculateTemporaryObservation(endObservation, _endTime);
        }

        // Formula: Δ_amount / Δ_time
        return (endObservation.cumulativeBalance - startObservation.cumulativeBalance) / (_endTime - _startTime);
    }

    /// @inheritdoc ITwabController
    function getAccount(address _account) public view returns (AccountDetails memory) {
        return _accounts[_account];
    }

    /// @inheritdoc ITwabController
    function getTotalSupplyAccount() public view returns (AccountDetails memory) {
        return _totalSupplyAccount;
    }

    /// @inheritdoc ITwabController
    function getTotalSupply() public view returns (uint256) {
        return _totalSupplyAccount.balance;
    }

    /* ===================== Internal & Private Functions ===================== */

    /**
     * @notice Increases a user's account balance and records the corresponding observation.
     * @param _account User account.
     * @param _amount Amount by which the user's account balance will increase.
     * @return newBalance New user account balance.
     * @return observation Recorded observation.
     * @return isNewObservation Flag indicating whether or not the observation is new or overwrote the latest one.
     */
    function _increaseBalance(AccountDetails storage _account, uint256 _amount)
        internal
        returns (uint256 newBalance, Observation memory observation, bool isNewObservation)
    {
        // Increases the user's account balance.
        newBalance = _account.balance + _amount;
        _account.balance = newBalance;

        // Records the corresponding observation.
        (observation, isNewObservation) = _recordObservation(_account);
    }

    /**
     * @notice Decreases a user's account balance and records the corresponding observation.
     * @param _account User account.
     * @param _amount Amount by which the user's account balance will decrease.
     * @return newBalance New user account balance.
     * @return observation Recorded observation.
     * @return isNewObservation Flag indicating whether or not the observation is new or overwrote the latest one.
     */
    function _decreaseBalance(AccountDetails storage _account, uint256 _amount)
        internal
        returns (uint256 newBalance, Observation memory observation, bool isNewObservation)
    {
        // Decreases the user's account balance.
        newBalance = _account.balance - _amount;
        _account.balance = newBalance;

        // Records the corresponding observation.
        (observation, isNewObservation) = _recordObservation(_account);
    }

    /**
     * @notice Either updates the latest observation or records a new one, given an account with updated balance.
     * @param _account User account.
     * @return observation The new or updated observation.
     * @return isNew Flag indicating whether or not the observation is new or overwrote the latest one.
     */
    function _recordObservation(AccountDetails storage _account)
        internal
        returns (Observation memory observation, bool isNew)
    {
        // Gets the current period.
        uint256 currentPeriod = _getPeriod(block.timestamp);

        // Gets the newest recorded observation index.
        uint256 lastObservationIndex = RingBufferLib.newestIndex(_account.nextObservationIndex, MAX_CARDINALITY);
        // Sets the newest observation index as the next index as it optimistically assumes the latest observation will be overridden.
        uint256 nextIndex = lastObservationIndex;
        // Gets the latest recorded observation.
        Observation memory lastObservation = _account.observations[lastObservationIndex];
        // Gets the period when the latest observation was recorded.
        uint256 lastPeriod = _getPeriod(lastObservation.timestamp);

        uint256 cardinality = _account.cardinality;
        // Check if it is a new observation.
        // - It's a new observation if the user has no recorded observations yet or we're in a new period.
        isNew = cardinality == 0 || currentPeriod > lastPeriod;

        // Updates user's account `nextObservationIndex` and `cardinality` if it is a new observation.
        if (isNew) {
            // Overrides next observation index, since it is a new observation.
            nextIndex = _account.nextObservationIndex;
            _account.nextObservationIndex = RingBufferLib.nextIndex(nextIndex, MAX_CARDINALITY);
            // Account's cardinality is increment by one only until it reaches the `MAX_CARDINALITY`.
            _account.cardinality = cardinality < MAX_CARDINALITY ? cardinality + 1 : MAX_CARDINALITY;
        }

        // Creates a new observation.
        observation = Observation({
            balance: _account.balance,
            cumulativeBalance: lastObservation.cumulativeBalance
                + lastObservation.balance * (block.timestamp - lastObservation.timestamp),
            timestamp: block.timestamp
        });

        // Records the observation at the corresponding index.
        _account.observations[nextIndex] = observation;
    }

    /**
     * @notice Retrieves the period, given a timestamp.
     * @dev Always return zero if the given timestamp is below the initial period offset.
     * @param _timestamp Timestamp used to determine the period.
     * @return Period of the given timestamp.
     */
    function _getPeriod(uint256 _timestamp) internal view returns (uint256) {
        if (_timestamp < PERIOD_OFFSET) return 0;
        return (_timestamp - PERIOD_OFFSET) / PERIOD_LENGTH;
    }

    /**
     * @notice Looks up the newest observation before or at a given timestamp.
     * @param _account User account.
     * @param _targetTime The target timestamp to look up.
     * @return The observation.
     */
    function _getPreviousOrAtObservation(AccountDetails memory _account, uint256 _targetTime)
        internal
        pure
        returns (Observation memory)
    {
        // Returns a zeroed observation if the user has no recorded observations yet.
        if (_account.cardinality == 0) return Observation({cumulativeBalance: 0, balance: 0, timestamp: 0});

        // Gets the oldest recorded observation.
        uint256 oldestIndex =
            RingBufferLib.oldestIndex(_account.nextObservationIndex, _account.cardinality, MAX_CARDINALITY);
        Observation memory oldestObservation = _account.observations[oldestIndex];

        // If the target timestamp is older than the oldest observation.
        if (oldestObservation.timestamp > _targetTime) {
            // Reverts if account cardinality reached `MAX_CARDINALITY`, since the previous observations have been overridden.
            require(_account.cardinality < MAX_CARDINALITY, TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY());
            // Returns a zeroed observation, since the account only has observations that are newer than the target timestamp.
            return Observation({cumulativeBalance: 0, balance: 0, timestamp: 0});
        }

        // From this point on, it is known that the target timestamp isn't older than the oldest observation.
        // If the account has only one observation recorded, returns the oldest one.
        if (_account.cardinality == 1) return oldestObservation;

        // Gets the newest recorded observation.
        uint256 newestIndex = RingBufferLib.newestIndex(_account.nextObservationIndex, _account.cardinality);
        Observation memory newestObservation = _account.observations[newestIndex];

        // Returns the newest observation if it was recorded before or at the target timestamp.
        if (newestObservation.timestamp <= _targetTime) return newestObservation;

        // If account has only two observations, returns the oldest, since it's known to be the only observation recorded before the target timestamp.
        if (_account.cardinality == 2) return oldestObservation;

        // Otherwise, performs a binarySearch to find the observation before or at the target timestamp.
        (Observation memory prevOrAtObservation,, Observation memory afterOrAtObservation,) =
            _binarySearch(_account.observations, newestIndex, oldestIndex, _targetTime, _account.cardinality);

        // If `afterOrAtObservation` is at the target timestamp, it is returned.
        if (afterOrAtObservation.timestamp == _targetTime) return afterOrAtObservation;

        return prevOrAtObservation;
    }

    /**
     * @notice Fetches observations `beforeOrAt` and `afterOrAt` a `_targetTime`.
     * @dev The `_targetTime` must fall within the boundaries of the provided `_observations`, meaning the `_targetTime`
     *      must be older than the newest observation and younger, or the same age as, the oldest observation.
     * @param _observations List of observations to perfom the search.
     * @param _newestIndex Index of the newest observation - right side of the circular buffer.
     * @param _oldestIndex Index of the oldest observation - left side of the circular buffer.
     * @param _targetTime Timestamp at which the observation is searched.
     * @param _cardinality Number of observations recorded in the circular buffer.
     * @return beforeOrAt Observation recorded before or at the target timestamp.
     * @return beforeOrAtIndex Index of the observation recorded before or at the target timestamp.
     * @return afterOrAt Observation recorded after or at the target timestamp.
     * @return afterOrAtIndex Index of the observation recorded after or at the target timestamp.
     */
    function _binarySearch(
        Observation[MAX_CARDINALITY] memory _observations,
        uint256 _newestIndex,
        uint256 _oldestIndex,
        uint256 _targetTime,
        uint256 _cardinality
    )
        internal
        pure
        returns (
            Observation memory beforeOrAt,
            uint256 beforeOrAtIndex,
            Observation memory afterOrAt,
            uint256 afterOrAtIndex
        )
    {
        uint256 leftSide = _oldestIndex;
        // If `_newestIndex` is less than `_oldestIndex`, it means that we've wrapped around the circular buffer
        // So the most recent observation will be at `_oldestIndex + _cardinality - 1`.
        uint256 rightSide = _newestIndex < leftSide ? leftSide + _cardinality - 1 : _newestIndex;
        uint256 currentIndex;

        // Search starts in the middle of the `leftSide` and `rightSide`.
        // After each iteration, the search is narrowed down to the left or right.
        while (true) {
            // Computes the divison by two with bit-shifting.
            currentIndex = (leftSide + rightSide) >> 1;

            // Gets the observation at current index.
            beforeOrAtIndex = RingBufferLib.wrap(currentIndex, _cardinality);
            beforeOrAt = _observations[beforeOrAtIndex];
            uint256 beforeOrAtTimestamp = beforeOrAt.timestamp;

            // Gets the observation at next index.
            afterOrAtIndex = RingBufferLib.nextIndex(currentIndex, _cardinality);
            afterOrAt = _observations[afterOrAtIndex];

            bool targetAfterOrAt = _targetTime >= beforeOrAtTimestamp;

            // Checks if the corresponding observation has been found.
            if (targetAfterOrAt && _targetTime <= afterOrAt.timestamp) break;

            // If target timestamp is newer or the same age as observation recorded at current index, then we keep searching higher.
            if (targetAfterOrAt) leftSide = currentIndex + 1;
            // Otherwise, we keep searching lower.
            else rightSide = currentIndex - 1;
        }
    }

    /**
     * @notice Calculates a temporary observation for a given time using the previous observation.
     * @dev This is used to extrapolate a balance for any given time.
     * @param _observation Previous observation.
     * @param _timestamp Timestamp to extrapolate to.
     * @return Temporary observation.
     */
    function _calculateTemporaryObservation(Observation memory _observation, uint256 _timestamp)
        internal
        pure
        returns (Observation memory)
    {
        return Observation({
            cumulativeBalance: _observation.cumulativeBalance + _observation.balance * (_timestamp - _observation.timestamp),
            balance: _observation.balance,
            timestamp: _timestamp
        });
    }
}
