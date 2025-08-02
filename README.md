# Ethereum Staking Smart Contract

A secure and feature-rich staking contract for ERC20 tokens on Ethereum with time-locked staking, reward distribution, and emergency withdrawal functionality.

## Features

- **ERC20 Token Staking**: Stake any ERC20 token
- **Time-Locked Staking**: 7-day lock period for staked tokens
- **Reward Distribution**: Automatic reward calculation based on staking duration
- **Emergency Withdrawal**: Option to withdraw with a 10% penalty
- **Security Features**:
  - ReentrancyGuard protection
  - Pausable functionality
  - Owner-only administrative functions
  - Minimum stake amount requirement

## Contract Architecture

### Main Components

1. **StakingContract.sol**: The main staking contract
   - Handles staking, withdrawals, and reward distribution
   - Implements security measures and access controls
   - Calculates rewards based on time and amount staked

2. **MockERC20.sol**: Mock token for testing
   - Used for both staking and reward tokens in development

### Key Functions

- `stake(uint256 amount)`: Stake tokens
- `withdraw(uint256 amount)`: Withdraw staked tokens after lock period
- `claimReward()`: Claim accumulated rewards
- `emergencyWithdraw()`: Withdraw with penalty (no lock period)
- `getStakeInfo(address user)`: View staking information

## Setup and Deployment

### Prerequisites

- Node.js v16 or higher
- npm or yarn

### Installation

```bash
npm install
```

### Compile Contracts

```bash
npm run compile
```

### Run Tests

```bash
npm run test
```

### Deploy to Local Network

1. Start a local Hardhat node:
```bash
npm run node
```

2. In a new terminal, deploy the contracts:
```bash
npm run deploy
```

### Deploy to Testnet/Mainnet

1. Update `.env` file with your private key and RPC URL
2. Update `hardhat.config.js` with network configuration
3. Run deployment script:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

## Contract Parameters

- **Reward Rate**: 100 tokens per second per 1e18 staked tokens
- **Minimum Stake**: 1 token (1e18 wei)
- **Lock Period**: 7 days
- **Emergency Withdrawal Penalty**: 10%

## Security Considerations

1. **Reentrancy Protection**: All state-changing functions use ReentrancyGuard
2. **Access Control**: Owner-only functions for administrative tasks
3. **Pausable**: Contract can be paused in case of emergency
4. **Input Validation**: All inputs are validated before processing
5. **Safe Math**: Solidity 0.8.x built-in overflow protection

## Gas Optimization

- Immutable variables for token addresses
- Efficient reward calculation algorithm
- Minimal storage operations

## Testing

The test suite covers:
- Staking functionality
- Withdrawal with time locks
- Reward calculation and claiming
- Emergency withdrawal with penalties
- Access control and security features

## License

MIT License
