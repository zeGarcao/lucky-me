// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ITwabController} from "./interfaces/ITwabController.sol";
import {RingBufferLib} from "./libraries/RingBufferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BalanceIncreased, BalanceDecreased, ObservationRecorded} from "./utils/Events.sol";
import {MAX_CARDINALITY, PERIOD_LENGTH} from "./utils/Constants.sol";
import {Observation, AccountDetails} from "./utils/Structs.sol";
import {
    TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE,
    TWAB_DECREASE_BALANCE__INVALID_AMOUNT,
    TWAB_INCREASE_BALANCE__INVALID_AMOUNT,
    TWAB_INIT__INVALID_PERIOD_OFFSET,
    TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE,
    TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY
} from "./utils/Errors.sol";

contract TwabController is ITwabController, Ownable {
    uint256 public immutable PERIOD_OFFSET;

    AccountDetails private _totalSupplyAccount;
    mapping(address => AccountDetails) private _accounts;

    constructor(uint256 _periodOffset) Ownable(msg.sender) {
        require(_periodOffset >= block.timestamp, TWAB_INIT__INVALID_PERIOD_OFFSET());
        PERIOD_OFFSET = _periodOffset;
    }

    function increaseBalance(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        require(_amount != 0, TWAB_INCREASE_BALANCE__INVALID_AMOUNT());

        (uint256 newBalance, Observation memory observation, bool isNewObservation) =
            _increaseBalance(_accounts[_account], _amount);

        _increaseBalance(_totalSupplyAccount, _amount);

        emit BalanceIncreased(_account, _amount, newBalance, block.timestamp);
        emit ObservationRecorded(_account, observation, isNewObservation);

        return newBalance;
    }

    function decreaseBalance(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        require(_amount != 0, TWAB_DECREASE_BALANCE__INVALID_AMOUNT());

        AccountDetails storage account = _accounts[_account];
        require(_amount <= account.balance, TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE());

        (uint256 newBalance, Observation memory observation, bool isNewObservation) =
            _decreaseBalance(_accounts[_account], _amount);

        _decreaseBalance(_totalSupplyAccount, _amount);

        emit BalanceDecreased(_account, _amount, newBalance, block.timestamp);
        emit ObservationRecorded(_account, observation, isNewObservation);

        return newBalance;
    }

    function getTwabBetween(address _account, uint256 _startTime, uint256 _endTime) external view returns (uint256) {
        require(_startTime <= _endTime, TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE());

        AccountDetails memory account = _accounts[_account];

        Observation memory endObservation = _getPreviousOrAtObservation(account, _endTime);

        if (_startTime == _endTime) return endObservation.balance;

        Observation memory startObservation = _getPreviousOrAtObservation(account, _startTime);

        if (startObservation.timestamp != _startTime) {
            startObservation = _calculateTemporaryObservation(startObservation, _startTime);
        }

        if (endObservation.timestamp != _endTime) {
            endObservation = _calculateTemporaryObservation(endObservation, _endTime);
        }

        return (endObservation.cumulativeBalance - startObservation.cumulativeBalance) / (_endTime - _startTime);
    }

    function getAccount(address _account) public view returns (AccountDetails memory) {
        return _accounts[_account];
    }

    function getTotalSupplyAccount() public view returns (AccountDetails memory) {
        return _totalSupplyAccount;
    }

    function _increaseBalance(AccountDetails storage _account, uint256 _amount)
        internal
        returns (uint256 newBalance, Observation memory observation, bool isNewObservation)
    {
        newBalance = _account.balance + _amount;
        _account.balance = newBalance;

        (observation, isNewObservation) = _recordObservation(_account);
    }

    function _decreaseBalance(AccountDetails storage _account, uint256 _amount)
        internal
        returns (uint256 newBalance, Observation memory observation, bool isNewObservation)
    {
        newBalance = _account.balance - _amount;
        _account.balance = newBalance;

        (observation, isNewObservation) = _recordObservation(_account);
    }

    function _recordObservation(AccountDetails storage _account)
        internal
        returns (Observation memory observation, bool isNew)
    {
        uint256 currentPeriod = _getPeriod(block.timestamp);

        uint256 lastObservationIndex = RingBufferLib.newestIndex(_account.nextObservationIndex, MAX_CARDINALITY);
        uint256 nextIndex = lastObservationIndex;
        Observation memory lastObservation = _account.observations[lastObservationIndex];
        uint256 lastPeriod = _getPeriod(lastObservation.timestamp);

        uint256 cardinality = _account.cardinality;
        isNew = cardinality == 0 || currentPeriod > lastPeriod;

        if (isNew) {
            nextIndex = _account.nextObservationIndex;
            _account.nextObservationIndex = RingBufferLib.nextIndex(nextIndex, MAX_CARDINALITY);
            _account.cardinality = cardinality < MAX_CARDINALITY ? cardinality + 1 : MAX_CARDINALITY;
        }

        observation = Observation({
            balance: _account.balance,
            cumulativeBalance: lastObservation.cumulativeBalance
                + lastObservation.balance * (block.timestamp - lastObservation.timestamp),
            timestamp: block.timestamp
        });

        _account.observations[nextIndex] = observation;
    }

    function _getPeriod(uint256 timestamp) internal view returns (uint256) {
        if (timestamp < PERIOD_OFFSET) return 0;
        return (timestamp - PERIOD_OFFSET) / PERIOD_LENGTH;
    }

    function _getPreviousOrAtObservation(AccountDetails memory _account, uint256 _targetTime)
        internal
        pure
        returns (Observation memory)
    {
        if (_account.cardinality == 0) return Observation({cumulativeBalance: 0, balance: 0, timestamp: 0});

        uint256 oldestIndex =
            RingBufferLib.oldestIndex(_account.nextObservationIndex, _account.cardinality, MAX_CARDINALITY);
        Observation memory oldestObservation = _account.observations[oldestIndex];

        if (oldestObservation.timestamp > _targetTime) {
            require(_account.cardinality < MAX_CARDINALITY, TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY());

            return Observation({cumulativeBalance: 0, balance: 0, timestamp: 0});
        }

        if (_account.cardinality == 1) return oldestObservation;

        uint256 newestIndex = RingBufferLib.newestIndex(_account.nextObservationIndex, _account.cardinality);
        Observation memory newestObservation = _account.observations[newestIndex];

        if (newestObservation.timestamp <= _targetTime) return newestObservation;

        if (_account.cardinality == 2) return oldestObservation;

        (Observation memory prevOrAtObservation,, Observation memory afterOrAtObservation,) =
            _binarySearch(_account.observations, newestIndex, oldestIndex, _targetTime, _account.cardinality);

        if (afterOrAtObservation.timestamp == _targetTime) return afterOrAtObservation;

        return prevOrAtObservation;
    }

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
        uint256 rightSide = _newestIndex < leftSide ? leftSide + _cardinality - 1 : _newestIndex;
        uint256 currentIndex;

        while (true) {
            currentIndex = (leftSide + rightSide) >> 1;

            beforeOrAtIndex = RingBufferLib.wrap(currentIndex, _cardinality);
            beforeOrAt = _observations[beforeOrAtIndex];
            uint256 beforeOrAtTimestamp = beforeOrAt.timestamp;

            afterOrAtIndex = RingBufferLib.nextIndex(currentIndex, _cardinality);
            afterOrAt = _observations[afterOrAtIndex];

            bool targetAfterOrAt = _targetTime >= beforeOrAtTimestamp;

            if (targetAfterOrAt && _targetTime <= afterOrAt.timestamp) break;

            if (targetAfterOrAt) leftSide = currentIndex + 1;
            else rightSide = currentIndex - 1;
        }
    }

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
