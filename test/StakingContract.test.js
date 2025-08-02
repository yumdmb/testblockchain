const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("StakingContract", function () {
  let stakingContract;
  let stakingToken;
  let rewardToken;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy tokens
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    stakingToken = await MockERC20.deploy("Staking Token", "STK");
    rewardToken = await MockERC20.deploy("Reward Token", "RWD");

    // Deploy staking contract
    const StakingContract = await ethers.getContractFactory("StakingContract");
    stakingContract = await StakingContract.deploy(
      stakingToken.address,
      rewardToken.address
    );

    // Setup: Transfer tokens to users and approve staking contract
    await stakingToken.transfer(user1.address, ethers.utils.parseEther("1000"));
    await stakingToken.transfer(user2.address, ethers.utils.parseEther("1000"));
    await stakingToken.connect(user1).approve(stakingContract.address, ethers.constants.MaxUint256);
    await stakingToken.connect(user2).approve(stakingContract.address, ethers.constants.MaxUint256);

    // Transfer reward tokens to staking contract
    await rewardToken.transfer(stakingContract.address, ethers.utils.parseEther("100000"));
  });

  describe("Staking", function () {
    it("Should stake tokens successfully", async function () {
      const stakeAmount = ethers.utils.parseEther("100");
      
      await expect(stakingContract.connect(user1).stake(stakeAmount))
        .to.emit(stakingContract, "Staked")
        .withArgs(user1.address, stakeAmount);

      const stakeInfo = await stakingContract.getStakeInfo(user1.address);
      expect(stakeInfo.stakedAmount).to.equal(stakeAmount);
    });

    it("Should reject stake below minimum", async function () {
      const stakeAmount = ethers.utils.parseEther("0.5");
      
      await expect(stakingContract.connect(user1).stake(stakeAmount))
        .to.be.revertedWith("Amount below minimum");
    });
  });

  describe("Withdrawing", function () {
    beforeEach(async function () {
      const stakeAmount = ethers.utils.parseEther("100");
      await stakingContract.connect(user1).stake(stakeAmount);
    });

    it("Should not allow withdrawal during lock period", async function () {
      await expect(stakingContract.connect(user1).withdraw(ethers.utils.parseEther("50")))
        .to.be.revertedWith("Still in lock period");
    });

    it("Should allow withdrawal after lock period", async function () {
      // Fast forward 7 days
      await time.increase(7 * 24 * 60 * 60);
      
      const withdrawAmount = ethers.utils.parseEther("50");
      await expect(stakingContract.connect(user1).withdraw(withdrawAmount))
        .to.emit(stakingContract, "Withdrawn")
        .withArgs(user1.address, withdrawAmount);
    });
  });

  describe("Rewards", function () {
    it("Should calculate rewards correctly", async function () {
      const stakeAmount = ethers.utils.parseEther("100");
      await stakingContract.connect(user1).stake(stakeAmount);
      
      // Fast forward 1 hour
      await time.increase(3600);
      
      const earned = await stakingContract.earned(user1.address);
      expect(earned).to.be.gt(0);
    });

    it("Should claim rewards successfully", async function () {
      const stakeAmount = ethers.utils.parseEther("100");
      await stakingContract.connect(user1).stake(stakeAmount);
      
      // Fast forward 1 day
      await time.increase(24 * 60 * 60);
      
      const earnedBefore = await stakingContract.earned(user1.address);
      await expect(stakingContract.connect(user1).claimReward())
        .to.emit(stakingContract, "RewardClaimed");
      
      const earnedAfter = await stakingContract.earned(user1.address);
      expect(earnedAfter).to.equal(0);
    });
  });

  describe("Emergency Withdraw", function () {
    it("Should allow emergency withdrawal with penalty", async function () {
      const stakeAmount = ethers.utils.parseEther("100");
      await stakingContract.connect(user1).stake(stakeAmount);
      
      const balanceBefore = await stakingToken.balanceOf(user1.address);
      await stakingContract.connect(user1).emergencyWithdraw();
      const balanceAfter = await stakingToken.balanceOf(user1.address);
      
      // Should receive 90% due to 10% penalty
      const expectedAmount = stakeAmount.mul(90).div(100);
      expect(balanceAfter.sub(balanceBefore)).to.equal(expectedAmount);
    });
  });
});
