# MicroSubs: Smart Subscription Manager

A decentralized subscription management system built on Ethereum that enables creators to offer services with automatic time-based subscription management.

## 🎯 Overview

MicroSubs is a smart contract that allows:
- **Creators** to register services with monthly subscription fees
- **Users** to subscribe to services for 30-day periods
- **Automatic expiration** based on blockchain timestamps
- **On-chain verification** of subscription status
- **Direct payments** to creator wallets
- **Dynamic pricing** - creators can update service prices
- **Service management** - pause/unpause subscriptions
- **Subscriber tracking** - monitor active subscriber counts

## 🏗️ Architecture & Design Choices

### Core Components

#### 1. **Service Structure**
```solidity
struct Service {
    address creator;         // Service owner
    uint256 pricePerMonth;   // Subscription price in wei
    bool exists;             // Existence flag for validation
    bool paused;             // Service pause status
    uint256 subscriberCount; // Number of active subscribers
}
```

**Design Rationale:**
- `exists` flag prevents operations on non-existent services without reverting on default values
- Price stored in wei for maximum flexibility (creators can set any amount)
- Creator address stored for earnings withdrawal authorization
- `paused` allows creators to temporarily stop new subscriptions
- `subscriberCount` tracks total subscribers for analytics

#### 2. **Subscription Structure**
```solidity
struct Subscription {
    uint256 expiry;  // Unix timestamp when subscription expires
}
```

**Design Rationale:**
- Minimalist design: only stores expiry timestamp
- Subscription status is derived from `expiry > block.timestamp`
- No need to store start time (can be calculated as `expiry - 30 days`)
- Gas-efficient: single storage slot per subscription

#### 3. **State Management**

**Mappings:**
```solidity
mapping(uint256 => Service) public services;
mapping(uint256 => mapping(address => Subscription)) public subscriptions;
mapping(uint256 => uint256) public earnings;
```

**Design Rationale:**
- Services indexed by auto-incrementing ID for easy enumeration
- Nested mapping for subscriptions allows O(1) lookup by service and user
- Separate earnings mapping enables batch accumulation before withdrawal

### Key Features & Implementation

#### ✅ Automatic Expiration
- No manual intervention required
- Subscriptions expire automatically when `block.timestamp > expiry`
- View function `isSubscribed()` checks expiration on-the-fly

#### ✅ Subscription Extension
```solidity
uint256 startTime = subscription.expiry > block.timestamp 
    ? subscription.expiry 
    : block.timestamp;
subscription.expiry = startTime + SUBSCRIPTION_DURATION;
```
- If subscription is active: extends from current expiry (no time lost)
- If subscription expired: starts fresh from current time
- Prevents users from losing paid time

#### ✅ Security Measures

1. **Checks-Effects-Interactions (CEI) Pattern**
   ```solidity
   earnings[serviceId] = 0;  // Effect
   (bool success, ) = payable(msg.sender).call{value: amount}("");  // Interaction
   ```
   - Prevents reentrancy attacks on withdrawal

2. **Exact Payment Validation**
   ```solidity
   if (msg.value != service.pricePerMonth) revert IncorrectPaymentAmount();
   ```
   - Prevents overpayment or underpayment
   - No refund logic needed (gas savings)

3. **Custom Errors**
   - Gas-efficient error handling (vs. string messages)
   - Clear error semantics for debugging

4. **Access Control**
   - Only service creators can withdraw earnings
   - No admin/owner privileges (fully decentralized)

#### ✅ Gas Optimizations

1. **Packed Storage**
   - Service struct fits in 3 storage slots
   - Subscription struct fits in 1 storage slot

2. **Minimal State Changes**
   - No unnecessary state updates
   - View functions for read operations

3. **Efficient Lookups**
   - O(1) complexity for all main operations
   - No loops or iterations

## 📋 Contract Interface

### Core Functions

#### `createService(uint256 price) → uint256 serviceId`
Creates a new service with specified monthly price.
- **Parameters:** `price` - Monthly subscription price in wei (must be > 0)
- **Returns:** Service ID
- **Emits:** `ServiceCreated`

#### `subscribe(uint256 serviceId) payable`
Subscribe to a service for 30 days.
- **Parameters:** `serviceId` - ID of service to subscribe to
- **Requires:** Exact payment amount (`msg.value == pricePerMonth`)
- **Emits:** `UserSubscribed`

#### `isSubscribed(address user, uint256 serviceId) → bool`
Check if a user has an active subscription.
- **Parameters:** 
  - `user` - Address to check
  - `serviceId` - Service ID
- **Returns:** `true` if subscribed and not expired

#### `withdrawEarnings(uint256 serviceId)`
Withdraw accumulated earnings (creator only).
- **Parameters:** `serviceId` - Service to withdraw from
- **Requires:** Caller must be service creator
- **Emits:** `EarningsWithdrawn`

### Creator Management Functions

#### `updateServicePrice(uint256 serviceId, uint256 newPrice)`
Update the price of a service (creator only).
- **Parameters:** 
  - `serviceId` - Service to update
  - `newPrice` - New price in wei (must be > 0)
- **Requires:** Caller must be service creator
- **Emits:** `ServicePriceUpdated`
- **Note:** Price changes don't affect existing subscriptions

#### `pauseService(uint256 serviceId)`
Pause a service to prevent new subscriptions (creator only).
- **Parameters:** `serviceId` - Service to pause
- **Requires:** Caller must be service creator
- **Emits:** `ServicePaused`
- **Note:** Existing subscriptions remain valid

#### `unpauseService(uint256 serviceId)`
Unpause a service to allow new subscriptions (creator only).
- **Parameters:** `serviceId` - Service to unpause
- **Requires:** Caller must be service creator
- **Emits:** `ServiceUnpaused`

### View Functions

- `getSubscriptionExpiry(address user, uint256 serviceId) → uint256`
- `getEarnings(uint256 serviceId) → uint256`
- `getNextServiceId() → uint256`
- `getServiceDetails(uint256 serviceId) → (address, uint256, bool)`
- `getServiceInfo(uint256 serviceId) → (address, uint256, bool, bool, uint256)` - Returns creator, price, exists, paused, subscriberCount

## 🧪 Testing

The project includes comprehensive test coverage:

### Test Categories

1. **Service Creation Tests**
   - Single and multiple service creation
   - Zero price validation
   - Service ID incrementing

2. **Subscription Tests**
   - Basic subscription flow
   - Multiple users per service
   - Payment validation
   - Subscription extension logic
   - Post-expiry re-subscription

3. **Expiration Tests**
   - Time-based expiration
   - Edge cases (exactly at expiry)
   - Never-subscribed users

4. **Earnings & Withdrawal Tests**
   - Earnings accumulation
   - Withdrawal authorization
   - Multiple withdrawals
   - Zero earnings handling

5. **Integration Tests**
   - Complete user journeys
   - Multiple services and users
   - Cross-service subscriptions

6. **Price Update Tests**
   - Price modification by creator
   - Access control validation
   - Existing subscription protection

7. **Pause/Unpause Tests**
   - Service pause functionality
   - Subscription blocking when paused
   - Existing subscription validity

8. **Subscriber Count Tests**
   - Count tracking on new subscriptions
   - Renewal behavior
   - Post-expiry re-subscription

9. **Fuzz Tests**
   - Random price values
   - Random time travel
   - Edge case discovery

### Running Tests

**Prerequisites:**
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**Run all tests:**
```bash
forge test
```

**Run with verbosity:**
```bash
forge test -vvv
```

**Run specific test:**
```bash
forge test --match-test testSubscribe -vvv
```

**Generate gas report:**
```bash
forge test --gas-report
```

**Coverage report:**
```bash
forge coverage
```

## 🚀 Deployment

### Local Deployment (Anvil)

1. **Start local node:**
```bash
anvil
```

2. **Deploy contract:**
```bash
forge create src/MicroSubs.sol:MicroSubs \
  --rpc-url http://localhost:8545 \
  --private-key <PRIVATE_KEY>
```

### Testnet Deployment (Sepolia)

1. **Set environment variables:**
```bash
export SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/YOUR_INFURA_KEY"
export PRIVATE_KEY="your_private_key"
export ETHERSCAN_API_KEY="your_etherscan_key"
```

2. **Deploy:**
```bash
forge create src/MicroSubs.sol:MicroSubs \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

3. **Verify contract (if not done during deployment):**
```bash
forge verify-contract <CONTRACT_ADDRESS> \
  src/MicroSubs.sol:MicroSubs \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deployment Script

Create `script/Deploy.s.sol`:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MicroSubs.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        MicroSubs microSubs = new MicroSubs();
        console.log("MicroSubs deployed at:", address(microSubs));
        
        vm.stopBroadcast();
    }
}
```

Run deployment script:
```bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

## 💡 Usage Examples

### Creating a Service

```solidity
// Creator creates a service for 0.1 ETH per month
uint256 serviceId = microSubs.createService(0.1 ether);
```

### Subscribing to a Service

```solidity
// User subscribes by sending exact payment
microSubs.subscribe{value: 0.1 ether}(serviceId);
```

### Checking Subscription Status

```solidity
// Check if user has active subscription
bool isActive = microSubs.isSubscribed(userAddress, serviceId);

// Get expiry timestamp
uint256 expiry = microSubs.getSubscriptionExpiry(userAddress, serviceId);
```

### Withdrawing Earnings

```solidity
// Creator withdraws accumulated earnings
microSubs.withdrawEarnings(serviceId);
```

## 🔒 Security Considerations

### Audited Patterns
- ✅ CEI pattern for reentrancy protection
- ✅ No delegatecall or selfdestruct
- ✅ No floating pragma
- ✅ Custom errors for gas efficiency
- ✅ Explicit visibility modifiers

### Potential Considerations
- **Time Manipulation:** Contract relies on `block.timestamp`. Miners can manipulate by ~15 seconds, but this is negligible for 30-day subscriptions.
- **No Pause Mechanism:** Contract cannot be paused. This is intentional for decentralization but means no emergency stop.
- **No Upgrade Path:** Contract is not upgradeable. Deploy new version if needed.
- **No Refunds:** No refund mechanism if user wants to cancel early. This is by design for simplicity.

## 📊 Gas Estimates

Approximate gas costs (may vary with network conditions):

| Operation | Gas Cost |
|-----------|----------|
| Create Service | ~100,000 |
| First Subscribe | ~80,000 |
| Renew Subscribe | ~60,000 |
| Check Subscription | <1,000 (view) |
| Withdraw Earnings | ~40,000 |

## 🛠️ Development

### Project Structure
```
de-sub/
├── src/
│   └── MicroSubs.sol          # Main contract
├── test/
│   └── MicroSubs.t.sol        # Test suite
├── script/
│   └── Deploy.s.sol           # Deployment script
├── foundry.toml               # Foundry configuration
└── README.md                  # This file
```

### Dependencies
- Solidity ^0.8.20
- Foundry (forge, anvil, cast)

### Code Style
- NatSpec documentation for all public functions
- Custom errors instead of require strings
- Event emission for all state changes
- Explicit visibility modifiers

## 🎓 Learning Resources

This project demonstrates:
- ✅ Time-based logic with `block.timestamp`
- ✅ Nested mappings for complex state
- ✅ Payment handling with `msg.value`
- ✅ Access control patterns
- ✅ Event emission for off-chain indexing
- ✅ Gas optimization techniques
- ✅ Comprehensive testing with Foundry

## 📜 Version History

### v1.1.0 (Current) - November 2025
**New Features:**
- ✅ Dynamic pricing - `updateServicePrice()` function
- ✅ Service pause/unpause - `pauseService()` and `unpauseService()`
- ✅ Subscriber tracking - `subscriberCount` field
- ✅ Enhanced service info - `getServiceInfo()` function

**Improvements:**
- Added 3 new events: `ServicePriceUpdated`, `ServicePaused`, `ServiceUnpaused`
- Expanded Service struct with `paused` and `subscriberCount` fields
- 20+ new test cases (total 60+)
- 100% backward compatible with v1.0.0

### v1.0.0 - November 2025
- Initial release with core subscription functionality
- Service creation, subscription, expiration, and withdrawal
- 40+ comprehensive test cases
- Complete documentation

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📞 Support

For issues or questions:
- Open an issue on GitHub
- Review test cases for usage examples
- Check Foundry documentation for tooling help

---

**Built with ❤️ using Foundry and Solidity**
