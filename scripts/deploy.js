const hre = require("hardhat");

async function main() {
  console.log("Deploying Staking Contract...");

  // Deploy mock tokens for testing
  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
  
  // Deploy staking token
  const stakingToken = await MockERC20.deploy("Staking Token", "STK");
  await stakingToken.deployed();
  console.log("Staking Token deployed to:", stakingToken.address);
  
  // Deploy reward token
  const rewardToken = await MockERC20.deploy("Reward Token", "RWD");
  await rewardToken.deployed();
  console.log("Reward Token deployed to:", rewardToken.address);
  
  // Deploy staking contract
  const StakingContract = await hre.ethers.getContractFactory("StakingContract");
  const stakingContract = await StakingContract.deploy(
    stakingToken.address,
    rewardToken.address
  );
  await stakingContract.deployed();
  console.log("Staking Contract deployed to:", stakingContract.address);
  
  // Transfer reward tokens to staking contract
  const rewardAmount = hre.ethers.utils.parseEther("100000"); // 100k tokens
  await rewardToken.transfer(stakingContract.address, rewardAmount);
  console.log("Transferred reward tokens to staking contract");
  
  console.log("\nDeployment complete!");
  console.log("------------------------");
  console.log("Staking Token:", stakingToken.address);
  console.log("Reward Token:", rewardToken.address);
  console.log("Staking Contract:", stakingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
