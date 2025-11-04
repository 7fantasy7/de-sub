# MicroSubs Quick Start Guide

Get up and running with MicroSubs in 5 minutes!

## Prerequisites

Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Installation

```bash
# Clone or navigate to project
cd de-sub

# Install dependencies (if any)
forge install

# Build the project
forge build
```

## Run Tests

```bash
# Run all tests
forge test

# Run with detailed output
forge test -vvv

# Run specific test
forge test --match-test testSubscribe -vvv

# Generate gas report
forge test --gas-report

# Check coverage
forge coverage
```

## Local Development

### 1. Start Local Blockchain

```bash
# Terminal 1: Start Anvil (local Ethereum node)
anvil
```

This will give you 10 test accounts with 10,000 ETH each.

### 2. Deploy Contract

```bash
# Terminal 2: Deploy to local network
forge create src/MicroSubs.sol:MicroSubs \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Save the deployed contract address!

### 3. Interact with Contract

Using `cast` (Foundry's CLI tool):

```bash
# Set variables
CONTRACT_ADDRESS=<your_deployed_address>
CREATOR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
USER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# Create a service (0.1 ETH per month)
cast send $CONTRACT_ADDRESS \
  "createService(uint256)" 100000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Check service details (serviceId = 0)
cast call $CONTRACT_ADDRESS \
  "getServiceDetails(uint256)" 0 \
  --rpc-url http://localhost:8545

# Subscribe to service (as different user)
cast send $CONTRACT_ADDRESS \
  "subscribe(uint256)" 0 \
  --value 0.1ether \
  --rpc-url http://localhost:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# Check if user is subscribed
cast call $CONTRACT_ADDRESS \
  "isSubscribed(address,uint256)" $USER 0 \
  --rpc-url http://localhost:8545

# Check subscription expiry
cast call $CONTRACT_ADDRESS \
  "getSubscriptionExpiry(address,uint256)" $USER 0 \
  --rpc-url http://localhost:8545

# Check earnings
cast call $CONTRACT_ADDRESS \
  "getEarnings(uint256)" 0 \
  --rpc-url http://localhost:8545

# Withdraw earnings (as creator)
cast send $CONTRACT_ADDRESS \
  "withdrawEarnings(uint256)" 0 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## Testnet Deployment (Sepolia)

### 1. Setup Environment

```bash
# Copy example env file
cp .env.example .env

# Edit .env with your values
# - Get Sepolia ETH from faucet: https://sepoliafaucet.com/
# - Get Infura key: https://infura.io/
# - Get Etherscan key: https://etherscan.io/apis
```

### 2. Deploy

```bash
# Load environment variables
source .env

# Deploy and verify
forge create src/MicroSubs.sol:MicroSubs \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

Or use the deployment script:

```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

### 3. Interact on Testnet

Same as local, but use Sepolia RPC URL:

```bash
# Create service
cast send $CONTRACT_ADDRESS \
  "createService(uint256)" 100000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Subscribe
cast send $CONTRACT_ADDRESS \
  "subscribe(uint256)" 0 \
  --value 0.1ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Common Commands Cheat Sheet

### Testing
```bash
forge test                           # Run all tests
forge test -vvv                      # Verbose output
forge test --match-test <name>       # Run specific test
forge test --gas-report              # Gas usage report
forge coverage                       # Coverage report
forge snapshot                       # Gas snapshot
```

### Building
```bash
forge build                          # Compile contracts
forge clean                          # Clean artifacts
forge fmt                            # Format code
```

### Deployment
```bash
forge create <contract>              # Deploy contract
forge verify-contract <address>      # Verify on Etherscan
```

### Interaction
```bash
cast call <address> <sig> <args>     # Read-only call
cast send <address> <sig> <args>     # State-changing transaction
cast balance <address>               # Check ETH balance
cast block-number                    # Current block number
```

## Example User Flows

### Flow 1: Creator Creates Service

```bash
# 1. Creator creates a service for 0.05 ETH/month
cast send $CONTRACT_ADDRESS \
  "createService(uint256)" 50000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key <creator_key>

# 2. Get service ID from logs (will be 0 for first service)
# 3. Share service ID with potential subscribers
```

### Flow 2: User Subscribes

```bash
# 1. User checks service details
cast call $CONTRACT_ADDRESS \
  "getServiceDetails(uint256)" 0 \
  --rpc-url http://localhost:8545

# 2. User subscribes with exact payment
cast send $CONTRACT_ADDRESS \
  "subscribe(uint256)" 0 \
  --value 0.05ether \
  --rpc-url http://localhost:8545 \
  --private-key <user_key>

# 3. Verify subscription
cast call $CONTRACT_ADDRESS \
  "isSubscribed(address,uint256)" <user_address> 0 \
  --rpc-url http://localhost:8545
```

### Flow 3: Creator Withdraws Earnings

```bash
# 1. Check accumulated earnings
cast call $CONTRACT_ADDRESS \
  "getEarnings(uint256)" 0 \
  --rpc-url http://localhost:8545

# 2. Withdraw to creator wallet
cast send $CONTRACT_ADDRESS \
  "withdrawEarnings(uint256)" 0 \
  --rpc-url http://localhost:8545 \
  --private-key <creator_key>

# 3. Verify earnings reset to 0
cast call $CONTRACT_ADDRESS \
  "getEarnings(uint256)" 0 \
  --rpc-url http://localhost:8545
```

## Troubleshooting

### "Insufficient funds"
- Ensure account has enough ETH for transaction + gas
- On testnet, get ETH from faucet

### "Incorrect payment amount"
- Must send exact subscription price
- Check service price: `getServiceDetails(serviceId)`

### "Not service creator"
- Only creator can withdraw earnings
- Verify you're using correct private key

### "No earnings to withdraw"
- No subscriptions yet, or already withdrawn
- Check earnings: `getEarnings(serviceId)`

### "Service does not exist"
- Check service ID is valid
- Get next service ID: `getNextServiceId()`

## Next Steps

1. ✅ Run tests to understand functionality
2. ✅ Deploy locally and interact with `cast`
3. ✅ Read `DESIGN.md` for architecture details
4. ✅ Deploy to testnet and share with friends
5. ✅ Build a frontend (React + ethers.js)
6. ✅ Integrate with The Graph for indexing
7. ✅ Add to your portfolio!

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Ethereum.org](https://ethereum.org/en/developers/)
- [OpenZeppelin](https://docs.openzeppelin.com/)

## Need Help?

- Check test files for usage examples
- Read inline code comments
- Review `README.md` for detailed docs
- Open an issue on GitHub

Happy building! 🚀
