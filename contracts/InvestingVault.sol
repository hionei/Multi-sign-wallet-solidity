// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract InvestingVault is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20 for IERC20;

  struct Storage {
    IERC20 _token;
    uint256 _minimumAmount;
    uint256 _unlockTime;
    uint256 _withdrawPeriod;
    uint256 _tokenFactor;
    uint256 _totalInvested;
    uint256 _totalRewardDistributed;
    mapping(address => uint256) _initialInvest;
    mapping(address => uint256) _invest;
    mapping(address => uint256) _lastClaimed;
    mapping(address => uint256) _reward;
  }

  uint256 public constant BRONZE_THRESHOLD = 1_000;
  uint256 public constant SILVER_THRESHOLD = 10_000;
  uint256 public constant GOLD_THRESHOLD = 50_000;
  uint256 public constant PLATINUM_THRESHOLD = 100_000;
  uint256 public constant DIAMOND_THRESHOLD = 500_000;

  event InvestUpdated(address indexed user, uint256 amount);
  event RewardClaimed(address indexed user, uint256 amount);

  error TooSmallAmount();
  error NotAvailable();

  bytes32 private constant StorageLocation =
    0x81f2b887c4139019972bd6bf530fb5a1ee1f11eb1556b0c344eb0fb217c41200;

  function _getStorage() private pure returns (Storage storage $) {
    assembly {
      $.slot := StorageLocation
    }
  }

  function initialize(
    IERC20 _token,
    address _owner,
    uint256 _minimumAmount,
    uint256 _tokenFactor
  ) external initializer {
    Storage storage s = _getStorage();

    s._minimumAmount = _minimumAmount;
    s._token = _token;
    s._unlockTime = block.timestamp + 183 days;
    s._withdrawPeriod = 7 days;
    s._tokenFactor = _tokenFactor;

    __Ownable_init(_owner);
  }

  function deposit(uint256 _amount) external nonReentrant {
    Storage storage s = _getStorage();
    if (block.timestamp > s._unlockTime && s._initialInvest[msg.sender] == 0) {
      revert NotAvailable();
    }

    if (block.timestamp < s._unlockTime) {
      if (s._initialInvest[msg.sender] + _amount < s._minimumAmount) {
        revert TooSmallAmount();
      }

      unchecked {
        s._initialInvest[msg.sender] += _amount;
      }
      if (s._lastClaimed[msg.sender] == 0) {
        s._lastClaimed[msg.sender] = s._unlockTime;
      }
    } else {
      _updateReward(msg.sender);
    }

    unchecked {
      s._invest[msg.sender] += _amount;
      s._totalInvested += _amount;
    }

    IERC20(s._token).safeTransferFrom(msg.sender, address(this), _amount);

    emit InvestUpdated(msg.sender, s._invest[msg.sender]);
  }

  function withdraw(uint256 _amount) external {
    Storage storage s = _getStorage();

    if (
      s._invest[msg.sender] < _amount ||
      s._invest[msg.sender] == 0 ||
      block.timestamp < s._unlockTime
    ) {
      revert NotAvailable();
    }

    _updateReward(msg.sender);

    unchecked {
      s._invest[msg.sender] -= _amount;
      s._totalInvested -= _amount;
    }

    IERC20(s._token).safeTransfer(msg.sender, _amount);

    emit InvestUpdated(msg.sender, s._invest[msg.sender]);
  }

  function claimReward() external {
    Storage storage s = _getStorage();
    if (block.timestamp >= s._lastClaimed[msg.sender] + s._withdrawPeriod) {
      _updateReward(msg.sender);
    }

    uint256 reward = s._reward[msg.sender];
    s._reward[msg.sender] = 0;

    unchecked {
      s._totalRewardDistributed += reward;
    }

    s._token.safeTransfer(msg.sender, reward);

    emit RewardClaimed(msg.sender, reward);
  }

  function _getUserTier(
    address _user
  ) internal view returns (string memory _tier, uint256 _maxValue) {
    Storage storage s = _getStorage();

    if (s._initialInvest[_user] < BRONZE_THRESHOLD * s._tokenFactor) {
      _tier = "Iron";
      _maxValue = (s._initialInvest[_user] * 110) / 100;
    } else if (s._initialInvest[_user] < SILVER_THRESHOLD * s._tokenFactor) {
      _tier = "Bronze";
      _maxValue = (s._initialInvest[_user] * 115) / 100;
    } else if (s._initialInvest[_user] < GOLD_THRESHOLD * s._tokenFactor) {
      _tier = "Silver";
      _maxValue = (s._initialInvest[_user] * 120) / 100;
    } else if (s._initialInvest[_user] < PLATINUM_THRESHOLD * s._tokenFactor) {
      _tier = "Gold";
      _maxValue = (s._initialInvest[_user] * 125) / 100;
    } else if (s._initialInvest[_user] < DIAMOND_THRESHOLD * s._tokenFactor) {
      _tier = "Platinum";
      _maxValue = (s._initialInvest[_user] * 130) / 100;
    } else {
      _tier = "Diamond";
      _maxValue = (s._initialInvest[_user] * 140) / 100;
    }
  }

  function _getPendingReward(address _user) internal view returns (uint256 _reward) {
    Storage storage s = _getStorage();

    uint256 validAmount = s._invest[_user];
    (, uint256 _maxValue) = _getUserTier(_user);
    if (validAmount > _maxValue) {
      validAmount = _maxValue;
    }

    _reward = ((block.timestamp - s._lastClaimed[_user]) * validAmount) / 1_000 / 1 days;
  }

  function _updateReward(address _user) internal {
    Storage storage s = _getStorage();

    uint256 reward = _getPendingReward(_user);

    unchecked {
      s._reward[_user] += reward;
    }

    s._lastClaimed[_user] = block.timestamp;
  }

  function getTotalData()
    external
    view
    returns (uint256 totalInvested, uint256 totalRewardDistributed)
  {
    Storage storage s = _getStorage();

    totalInvested = s._totalInvested;
    totalRewardDistributed = s._totalRewardDistributed;
  }

  function getUserData(
    address _user
  )
    external
    view
    returns (
      uint256 invested,
      uint256 validInvest,
      uint256 reward,
      uint256 claimableReward,
      uint256 timeLeft,
      string memory tier
    )
  {
    Storage storage s = _getStorage();

    invested = s._invest[_user];
    validInvest = s._invest[_user];
    (string memory _tier, uint256 _maxValue) = _getUserTier(_user);
    if (validInvest > _maxValue) {
      validInvest = _maxValue;
    }

    tier = _tier;
    reward = s._reward[_user] + _getPendingReward(_user);
    claimableReward = s._reward[_user];

    if (block.timestamp >= s._lastClaimed[_user] + s._withdrawPeriod) {
      claimableReward += _getPendingReward(_user);
      timeLeft = 0;
    } else {
      timeLeft = s._lastClaimed[_user] + s._withdrawPeriod - block.timestamp;
    }
  }

  function invest(address _to, uint256 _amount) external onlyOwner {
    Storage storage s = _getStorage();

    s._token.safeTransfer(_to, _amount);
  }

  function investReturn(uint256 _amount) external onlyOwner {
    Storage storage s = _getStorage();

    s._token.safeTransferFrom(msg.sender, address(this), _amount);
  }
}
