// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title StakingContract
 * @dev A staking contract that allows users to stake ERC20 tokens and earn rewards
 */
contract StakingContract is ReentrancyGuard, Ownable, Pausable {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    
    uint256 public constant REWARD_RATE = 100; // 100 tokens per second per 1e18 staked tokens
    uint256 public constant MIN_STAKE_AMOUNT = 1e18; // Minimum 1 token
    uint256 public constant LOCK_PERIOD = 7 days; // 7 day lock period
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }
    
    mapping(address => Stake) public stakes;
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    
    constructor(address _stakingToken, address _rewardToken) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_rewardToken != address(0), "Invalid reward token");
        
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    /**
     * @dev Updates the reward per token stored
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        if (account != address(0)) {
            stakes[account].rewardDebt = earned(account);
        }
        _;
    }
    
    /**
     * @dev Calculates the reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored + 
            ((block.timestamp - lastUpdateTime) * REWARD_RATE * 1e18) / totalStaked;
    }
    
    /**
     * @dev Calculates earned rewards for an account
     */
    function earned(address account) public view returns (uint256) {
        Stake memory userStake = stakes[account];
        return (userStake.amount * (rewardPerToken() - userStake.rewardDebt)) / 1e18;
    }
    
    /**
     * @dev Stake tokens
     */
    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount >= MIN_STAKE_AMOUNT, "Amount below minimum");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;
        totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    /**
     * @dev Withdraw staked tokens and claim rewards
     */
    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        Stake storage userStake = stakes[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        require(userStake.amount >= amount, "Insufficient balance");
        require(block.timestamp >= userStake.timestamp + LOCK_PERIOD, "Still in lock period");
        
        userStake.amount -= amount;
        totalStaked -= amount;
        
        // Claim rewards
        uint256 reward = userStake.rewardDebt;
        if (reward > 0) {
            userStake.rewardDebt = 0;
            require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");
            emit RewardClaimed(msg.sender, reward);
        }
        
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Claim rewards without withdrawing
     */
    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = stakes[msg.sender].rewardDebt;
        require(reward > 0, "No rewards to claim");
        
        stakes[msg.sender].rewardDebt = 0;
        require(rewardToken.transfer(msg.sender, reward), "Transfer failed");
        
        emit RewardClaimed(msg.sender, reward);
    }
    
    /**
     * @dev Emergency withdraw without rewards (penalty)
     */
    function emergencyWithdraw() external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        uint256 amount = userStake.amount;
        require(amount > 0, "No stake to withdraw");
        
        userStake.amount = 0;
        userStake.rewardDebt = 0;
        totalStaked -= amount;
        
        // Apply 10% penalty for emergency withdrawal
        uint256 penalty = amount / 10;
        uint256 withdrawAmount = amount - penalty;
        
        require(stakingToken.transfer(msg.sender, withdrawAmount), "Transfer failed");
        require(stakingToken.transfer(owner(), penalty), "Penalty transfer failed");
        
        emit EmergencyWithdraw(msg.sender, withdrawAmount);
    }
    
    /**
     * @dev Get stake info for a user
     */
    function getStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 pendingReward,
        uint256 unlockTime,
        bool canWithdraw
    ) {
        Stake memory userStake = stakes[user];
        stakedAmount = userStake.amount;
        pendingReward = earned(user);
        unlockTime = userStake.timestamp + LOCK_PERIOD;
        canWithdraw = block.timestamp >= unlockTime;
    }
    
    /**
     * @dev Pause the contract (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Recover accidentally sent tokens (only owner)
     */
    function recoverToken(address token, uint256 amount) external onlyOwner {
        require(token != address(stakingToken), "Cannot recover staking token");
        IERC20(token).transfer(owner(), amount);
    }
}
