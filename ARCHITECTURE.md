# MicroSubs Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         MicroSubs Contract                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                    State Variables                      │   │
│  │                                                          │   │
│  │  • SUBSCRIPTION_DURATION = 30 days                      │   │
│  │  • _nextServiceId: uint256                              │   │
│  │                                                          │   │
│  │  Mappings:                                              │   │
│  │  • services: serviceId => Service                       │   │
│  │  • subscriptions: serviceId => user => Subscription     │   │
│  │  • earnings: serviceId => uint256                       │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                    Core Functions                       │   │
│  │                                                          │   │
│  │  1. createService(price) → serviceId                    │   │
│  │  2. subscribe(serviceId) [payable]                      │   │
│  │  3. isSubscribed(user, serviceId) → bool [view]         │   │
│  │  4. withdrawEarnings(serviceId)                         │   │
│  └────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### 1. Service Creation Flow

```
┌─────────┐
│ Creator │
└────┬────┘
     │
     │ createService(0.1 ETH)
     ↓
┌─────────────────────────┐
│   MicroSubs Contract    │
│                         │
│  1. Validate price > 0  │
│  2. Generate serviceId  │
│  3. Store Service       │
│  4. Emit event          │
└────────┬────────────────┘
         │
         │ ServiceCreated(serviceId, creator, price)
         ↓
    ┌─────────┐
    │  Event  │
    │  Logs   │
    └─────────┘

Result:
services[0] = {
    creator: 0x123...,
    pricePerMonth: 0.1 ETH,
    exists: true
}
```

### 2. Subscription Flow

```
┌──────┐
│ User │
└──┬───┘
   │
   │ subscribe(serviceId=0) + 0.1 ETH
   ↓
┌──────────────────────────────────┐
│      MicroSubs Contract          │
│                                  │
│  1. Validate service exists      │
│  2. Check payment amount         │
│  3. Calculate expiry:            │
│     - If active: extend          │
│     - If expired: start fresh    │
│  4. Update subscription          │
│  5. Add to earnings              │
│  6. Emit event                   │
└──────────┬───────────────────────┘
           │
           │ UserSubscribed(serviceId, user, expiry)
           ↓
      ┌─────────┐
      │  Event  │
      │  Logs   │
      └─────────┘

Result:
subscriptions[0][user] = {
    expiry: block.timestamp + 30 days
}
earnings[0] += 0.1 ETH
```

### 3. Subscription Check Flow

```
┌──────────┐
│  Anyone  │
└────┬─────┘
     │
     │ isSubscribed(user, serviceId)
     ↓
┌──────────────────────────────────┐
│      MicroSubs Contract          │
│                                  │
│  1. Get subscription.expiry      │
│  2. Compare with block.timestamp │
│  3. Return boolean               │
└────────┬─────────────────────────┘
         │
         │ return (expiry > block.timestamp)
         ↓
    ┌────────┐
    │  bool  │
    └────────┘

Logic:
if (expiry > block.timestamp) → true (active)
else → false (expired or never subscribed)
```

### 4. Earnings Withdrawal Flow

```
┌─────────┐
│ Creator │
└────┬────┘
     │
     │ withdrawEarnings(serviceId)
     ↓
┌──────────────────────────────────┐
│      MicroSubs Contract          │
│                                  │
│  1. Validate service exists      │
│  2. Check caller is creator      │
│  3. Check earnings > 0           │
│  4. Reset earnings (CEI)         │
│  5. Transfer ETH                 │
│  6. Emit event                   │
└────────┬─────────────────────────┘
         │
         │ EarningsWithdrawn(serviceId, creator, amount)
         ↓
    ┌─────────┐
    │  Event  │
    │  Logs   │
    └─────────┘

Result:
earnings[serviceId] = 0
creator.balance += amount
```

## State Transitions

### Subscription State Machine

```
┌──────────────────┐
│                  │
│  Never           │
│  Subscribed      │
│  (expiry = 0)    │
│                  │
└────────┬─────────┘
         │
         │ subscribe()
         ↓
┌──────────────────┐
│                  │
│  Active          │
│  Subscription    │
│  (expiry > now)  │
│                  │
└────────┬─────────┘
         │
         │ time passes
         │ (block.timestamp >= expiry)
         ↓
┌──────────────────┐
│                  │
│  Expired         │
│  Subscription    │
│  (expiry <= now) │
│                  │
└────────┬─────────┘
         │
         │ subscribe() again
         │
         └──────────┐
                    │
         ┌──────────┘
         ↓
┌──────────────────┐
│                  │
│  Active          │
│  Subscription    │
│  (new expiry)    │
│                  │
└──────────────────┘
```

## Storage Layout

### Service Storage

```
┌─────────────────────────────────────────┐
│  services[serviceId]                    │
├─────────────────────────────────────────┤
│  Slot 0: creator (address - 20 bytes)   │
│          exists (bool - 1 byte)         │
│          [11 bytes padding]             │
├─────────────────────────────────────────┤
│  Slot 1: pricePerMonth (uint256)        │
└─────────────────────────────────────────┘
Total: 2 storage slots per service
```

### Subscription Storage

```
┌─────────────────────────────────────────┐
│  subscriptions[serviceId][user]         │
├─────────────────────────────────────────┤
│  Slot 0: expiry (uint256)               │
└─────────────────────────────────────────┘
Total: 1 storage slot per subscription
```

### Earnings Storage

```
┌─────────────────────────────────────────┐
│  earnings[serviceId]                    │
├─────────────────────────────────────────┤
│  Slot 0: amount (uint256)               │
└─────────────────────────────────────────┘
Total: 1 storage slot per service
```

## Interaction Patterns

### Pattern 1: Creator Workflow

```
┌─────────┐
│ Creator │
└────┬────┘
     │
     ├─► createService(0.1 ETH)
     │   └─► serviceId = 0
     │
     ├─► Wait for subscribers...
     │
     ├─► Check earnings
     │   └─► getEarnings(0) = 0.5 ETH
     │
     └─► withdrawEarnings(0)
         └─► Receive 0.5 ETH
```

### Pattern 2: User Workflow

```
┌──────┐
│ User │
└──┬───┘
   │
   ├─► Browse services
   │   └─► getServiceDetails(0)
   │
   ├─► Subscribe
   │   └─► subscribe(0) + 0.1 ETH
   │
   ├─► Use service for 30 days
   │
   ├─► Check status
   │   └─► isSubscribed(user, 0) = true
   │
   ├─► Wait 30 days...
   │
   ├─► Check status again
   │   └─► isSubscribed(user, 0) = false
   │
   └─► Renew subscription
       └─► subscribe(0) + 0.1 ETH
```

### Pattern 3: Multi-Service Workflow

```
┌──────┐
│ User │
└──┬───┘
   │
   ├─► subscribe(service0) + 0.1 ETH
   │   └─► Active until Day 30
   │
   ├─► subscribe(service1) + 0.2 ETH
   │   └─► Active until Day 30
   │
   ├─► Day 15: Extend service0
   │   └─► subscribe(service0) + 0.1 ETH
   │       └─► Active until Day 60
   │
   └─► Day 30:
       ├─► service0: Still active (Day 60)
       └─► service1: Expired
```

## Access Control Matrix

```
┌──────────────────┬─────────┬──────┬─────────┐
│ Function         │ Creator │ User │ Anyone  │
├──────────────────┼─────────┼──────┼─────────┤
│ createService    │    ✓    │  ✓   │    ✓    │
│ subscribe        │    ✓    │  ✓   │    ✓    │
│ isSubscribed     │    ✓    │  ✓   │    ✓    │
│ withdrawEarnings │ ✓ (own) │  ✗   │    ✗    │
│ getServiceDetails│    ✓    │  ✓   │    ✓    │
│ getEarnings      │    ✓    │  ✓   │    ✓    │
└──────────────────┴─────────┴──────┴─────────┘

Legend:
✓ = Allowed
✗ = Reverts
✓ (own) = Only for own services
```

## Event Flow

```
Contract Events → Blockchain Logs → Off-Chain Indexing

┌──────────────────┐
│ ServiceCreated   │──┐
└──────────────────┘  │
                      │
┌──────────────────┐  │    ┌─────────────┐    ┌──────────────┐
│ UserSubscribed   │──┼───►│  Blockchain │───►│  The Graph   │
└──────────────────┘  │    │    Logs     │    │   Subgraph   │
                      │    └─────────────┘    └──────────────┘
┌──────────────────┐  │                              │
│ EarningsWithdrawn│──┘                              │
└──────────────────┘                                 ↓
                                              ┌──────────────┐
                                              │   Frontend   │
                                              │  Dashboard   │
                                              └──────────────┘
```

## Gas Cost Breakdown

```
Operation: createService(0.1 ETH)
├─ Base transaction cost: ~21,000 gas
├─ Storage writes:
│  ├─ services[id].creator: ~20,000 gas
│  ├─ services[id].pricePerMonth: ~20,000 gas
│  └─ services[id].exists: ~5,000 gas
├─ _nextServiceId increment: ~5,000 gas
└─ Event emission: ~2,000 gas
Total: ~100,000 gas

Operation: subscribe(serviceId)
├─ Base transaction cost: ~21,000 gas
├─ Storage reads:
│  ├─ services[id]: ~2,100 gas
│  └─ subscriptions[id][user]: ~2,100 gas
├─ Storage writes:
│  ├─ subscriptions[id][user].expiry: ~20,000 gas
│  └─ earnings[id]: ~5,000 gas (warm)
├─ Event emission: ~2,000 gas
└─ Payment processing: ~0 gas (built-in)
Total: ~80,000 gas (first time)
Total: ~60,000 gas (renewal, warm storage)

Operation: isSubscribed(user, serviceId) [view]
├─ Storage read: subscriptions[id][user].expiry
├─ Comparison: expiry > block.timestamp
└─ Return boolean
Total: <1,000 gas (view function, no transaction)

Operation: withdrawEarnings(serviceId)
├─ Base transaction cost: ~21,000 gas
├─ Storage reads:
│  ├─ services[id]: ~2,100 gas
│  └─ earnings[id]: ~2,100 gas
├─ Storage write:
│  └─ earnings[id] = 0: ~5,000 gas
├─ ETH transfer: ~2,300 gas
└─ Event emission: ~2,000 gas
Total: ~40,000 gas
```

## Security Boundaries

```
┌─────────────────────────────────────────────────────┐
│                External Boundary                     │
│  ┌───────────────────────────────────────────────┐ │
│  │            Public Functions                    │ │
│  │  • createService()                             │ │
│  │  • subscribe()                                 │ │
│  │  • isSubscribed()                              │ │
│  │  • withdrawEarnings()                          │ │
│  └────────────────┬──────────────────────────────┘ │
│                   │                                  │
│  ┌────────────────▼──────────────────────────────┐ │
│  │         Input Validation Layer                │ │
│  │  • require(price > 0)                         │ │
│  │  • require(service.exists)                    │ │
│  │  • require(msg.value == price)                │ │
│  │  • require(msg.sender == creator)             │ │
│  └────────────────┬──────────────────────────────┘ │
│                   │                                  │
│  ┌────────────────▼──────────────────────────────┐ │
│  │         Business Logic Layer                  │ │
│  │  • Calculate expiry                           │ │
│  │  • Update state                               │ │
│  │  • Emit events                                │ │
│  └────────────────┬──────────────────────────────┘ │
│                   │                                  │
│  ┌────────────────▼──────────────────────────────┐ │
│  │         Storage Layer (CEI Pattern)           │ │
│  │  1. Checks (validation)                       │ │
│  │  2. Effects (state changes)                   │ │
│  │  3. Interactions (external calls)             │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Time-Based Logic

```
Timeline: Subscription Lifecycle

Day 0                Day 15               Day 30              Day 45
│                    │                    │                   │
│ subscribe()        │                    │                   │
│ expiry = Day 30    │                    │                   │
├────────────────────┼────────────────────┤                   │
│                    │                    │                   │
│   isSubscribed()   │  isSubscribed()    │ isSubscribed()    │
│   = true           │  = true            │ = false           │
│                    │                    │                   │
│                    │ subscribe()        │                   │
│                    │ expiry = Day 45    │                   │
│                    ├────────────────────┼───────────────────┤
│                    │                    │                   │
│                    │                    │ isSubscribed()    │ isSubscribed()
│                    │                    │ = true            │ = false
│                    │                    │                   │
▼                    ▼                    ▼                   ▼
Active               Active               Expired             Expired
(30 days)            (extended to 45)     (at Day 30)        (at Day 45)
```

## Comparison with Traditional Systems

```
┌─────────────────────┬──────────────────┬─────────────────────┐
│ Feature             │ Traditional SaaS │ MicroSubs           │
├─────────────────────┼──────────────────┼─────────────────────┤
│ Payment Processing  │ Stripe/PayPal    │ Native ETH          │
│ Subscription Check  │ Database query   │ On-chain view       │
│ Expiration          │ Cron job         │ Automatic (time)    │
│ Cancellation        │ Immediate        │ Expires naturally   │
│ Refunds             │ Supported        │ Not supported       │
│ Fees                │ 2-3%             │ Gas only            │
│ Trust               │ Centralized      │ Trustless           │
│ Censorship          │ Possible         │ Resistant           │
│ Global Access       │ Restricted       │ Permissionless      │
└─────────────────────┴──────────────────┴─────────────────────┘
```

## Integration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Full Stack DApp                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Frontend   │◄────────┤  The Graph   │             │
│  │  (React)     │         │  (Indexer)   │             │
│  └──────┬───────┘         └──────▲───────┘             │
│         │                        │                      │
│         │ ethers.js              │ Events               │
│         │                        │                      │
│  ┌──────▼────────────────────────┴───────┐             │
│  │         Ethereum Network               │             │
│  │  ┌──────────────────────────────────┐ │             │
│  │  │      MicroSubs Contract          │ │             │
│  │  │                                  │ │             │
│  │  │  • createService()               │ │             │
│  │  │  • subscribe()                   │ │             │
│  │  │  • isSubscribed()                │ │             │
│  │  │  • withdrawEarnings()            │ │             │
│  │  └──────────────────────────────────┘ │             │
│  └─────────────────────────────────────────┘           │
│                                                          │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   MetaMask   │         │    IPFS      │             │
│  │  (Wallet)    │         │  (Metadata)  │             │
│  └──────────────┘         └──────────────┘             │
└─────────────────────────────────────────────────────────┘
```

---

This architecture provides a complete view of how MicroSubs operates at every level, from high-level user flows to low-level storage layouts and gas costs.
