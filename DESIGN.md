# MicroSubs Design Document

## Design Philosophy

MicroSubs follows these core principles:

### 1. **Simplicity First**
- Minimal state variables
- No complex inheritance
- Single responsibility per function
- Easy to audit and understand

### 2. **Gas Efficiency**
- Custom errors (saves ~50 gas per revert vs strings)
- Packed structs for optimal storage
- View functions for read operations
- No unnecessary state updates

### 3. **Security by Design**
- CEI pattern prevents reentrancy
- No external calls except ETH transfers
- Explicit access control
- No admin privileges (fully decentralized)

### 4. **User Experience**
- Automatic subscription extension (no time lost)
- Clear error messages
- Events for off-chain tracking
- Simple interface (4 main functions)

## Technical Decisions

### Why 30 Days Instead of Blocks?

**Decision:** Use `block.timestamp` and 30-day periods

**Rationale:**
- More intuitive for users (calendar-based)
- Consistent duration regardless of network congestion
- Standard subscription model
- Acceptable miner manipulation risk (~15 seconds vs 30 days)

**Alternative Considered:** Block-based (e.g., ~216,000 blocks)
- ❌ Variable duration based on network
- ❌ Harder to reason about
- ❌ Doesn't match real-world subscription models

### Why No Refunds?

**Decision:** No cancellation or refund mechanism

**Rationale:**
- Simplifies contract logic
- Reduces gas costs
- Prevents gaming the system
- Matches many real-world subscriptions (prepaid)

**Alternative Considered:** Pro-rata refunds
- ❌ Complex calculation logic
- ❌ Higher gas costs
- ❌ Potential for abuse
- ❌ Creator cash flow uncertainty

### Why Separate Earnings Mapping?

**Decision:** Store earnings separately from direct transfers

**Rationale:**
- Batch accumulation before withdrawal
- Clear accounting trail
- Prevents forced ETH sends
- Enables future features (e.g., revenue sharing)

**Alternative Considered:** Direct transfers on subscribe
- ❌ Higher gas per subscription
- ❌ Reentrancy risk
- ❌ No batch operations
- ✅ Simpler logic (but we chose security/efficiency)

### Why Auto-Incrementing Service IDs?

**Decision:** Use sequential uint256 IDs starting from 0

**Rationale:**
- Predictable and easy to enumerate
- Gas-efficient (no hashing)
- Simple off-chain indexing
- No collision risk

**Alternative Considered:** Hash-based IDs (keccak256)
- ❌ Higher gas cost
- ❌ Harder to enumerate
- ✅ More "random" (but unnecessary)

### Why No Service Deletion?

**Decision:** Services cannot be deleted once created

**Rationale:**
- Preserves historical data
- Prevents breaking existing subscriptions
- Simpler state management
- Creator can just stop promoting

**Alternative Considered:** Soft delete (active flag)
- ❌ More complex logic
- ❌ Need to handle existing subscriptions
- ✅ Cleaner state (but not worth complexity)

### Why Exact Payment Required?

**Decision:** Revert if `msg.value != pricePerMonth`

**Rationale:**
- No refund logic needed (gas savings)
- Clear user intent
- Prevents accidental overpayment
- Simpler accounting

**Alternative Considered:** Accept overpayment, refund difference
- ❌ More complex
- ❌ Higher gas costs
- ❌ Reentrancy risk on refund
- ❌ Unclear user intent

## Architecture Patterns

### State Machine

Subscriptions follow a simple state machine:

```
[Never Subscribed] --subscribe()--> [Active]
       ↑                               |
       |                          (time passes)
       |                               ↓
       +----subscribe()------------ [Expired]
```

States are implicit (derived from expiry timestamp):
- **Never Subscribed:** `expiry == 0`
- **Active:** `expiry > block.timestamp`
- **Expired:** `expiry > 0 && expiry <= block.timestamp`

### Access Control

Simple role-based access:
- **Anyone:** Can create services, subscribe, check subscriptions
- **Service Creator:** Can withdraw earnings for their services
- **No Admin:** No privileged accounts

### Event-Driven Architecture

All state changes emit events for off-chain indexing:
```solidity
event ServiceCreated(uint256 indexed serviceId, address indexed creator, uint256 pricePerMonth);
event UserSubscribed(uint256 indexed serviceId, address indexed user, uint256 expiry);
event EarningsWithdrawn(uint256 indexed serviceId, address indexed creator, uint256 amount);
```

This enables:
- Real-time notifications
- Historical data analysis
- Off-chain dashboards
- Subgraph integration

## Scalability Considerations

### Current Limitations
- No pagination for services (must enumerate off-chain)
- No bulk operations
- No service discovery mechanism

### Future Enhancements (Not Implemented)
1. **Service Metadata:** IPFS hash for description, images
2. **Tiered Pricing:** Multiple subscription tiers per service
3. **Referral System:** Affiliate rewards
4. **Discount Codes:** Promotional pricing
5. **Gifting:** Subscribe on behalf of others
6. **Auto-Renewal:** Approve contract to pull funds

### Why Not Implemented?
These features add complexity. MicroSubs is intentionally minimal to:
- Reduce attack surface
- Lower gas costs
- Easier auditing
- Serve as educational example

## Testing Strategy

### Test Pyramid

1. **Unit Tests (80%):** Test individual functions in isolation
2. **Integration Tests (15%):** Test complete user flows
3. **Fuzz Tests (5%):** Test edge cases with random inputs

### Coverage Goals
- ✅ 100% function coverage
- ✅ 100% branch coverage
- ✅ All error conditions tested
- ✅ Time-based logic verified
- ✅ Access control validated

### Test Utilities
- `vm.prank()`: Simulate different callers
- `vm.warp()`: Time travel for expiration tests
- `vm.deal()`: Fund test accounts
- `vm.expectRevert()`: Verify error conditions
- `vm.expectEmit()`: Verify events

## Security Analysis

### Threat Model

**Potential Attacks:**
1. **Reentrancy:** ✅ Mitigated with CEI pattern
2. **Integer Overflow:** ✅ Solidity 0.8+ has built-in checks
3. **Time Manipulation:** ⚠️ Acceptable risk (15s vs 30 days)
4. **Front-Running:** ⚠️ Low impact (subscriptions are additive)
5. **DoS:** ✅ No loops or unbounded operations

**Trust Assumptions:**
- Users trust service creators to deliver promised service
- Creators trust users won't share access credentials
- All parties trust Ethereum consensus

### Audit Checklist
- ✅ No delegatecall
- ✅ No selfdestruct
- ✅ No assembly
- ✅ No external calls (except ETH transfer)
- ✅ CEI pattern followed
- ✅ Access control implemented
- ✅ Events for all state changes
- ✅ Custom errors for gas efficiency
- ✅ No floating pragma
- ✅ Explicit visibility

## Comparison with Alternatives

### vs. Superfluid
- **MicroSubs:** Fixed 30-day periods, simpler
- **Superfluid:** Continuous streaming, more complex

### vs. Unlock Protocol
- **MicroSubs:** Time-based only, no NFTs
- **Unlock Protocol:** NFT-based memberships, more features

### vs. Manual Payments
- **MicroSubs:** Automated expiration, on-chain verification
- **Manual:** Requires off-chain tracking, trust

## Architecture Overview

### Data Flow
```
Creator → createService() → Service stored on-chain
User → subscribe() → Payment sent + Expiry set
Anyone → isSubscribed() → Check if active
Creator → withdrawEarnings() → Receive payments
Creator → updateServicePrice() → Update pricing (v1.1.0)
Creator → pauseService() → Pause new subs (v1.1.0)
```

### State Management
- **Services:** `serviceId → Service` (creator, price, exists, paused, subscriberCount)
- **Subscriptions:** `serviceId → user → Subscription` (expiry timestamp)
- **Earnings:** `serviceId → amount` (accumulated payments)

## Future Considerations

### Potential Upgrades (V2)
1. **Variable Duration:** Allow 1, 3, 6, 12 month subscriptions
2. **Service Metadata:** IPFS integration for descriptions
3. **Service Categories:** Tag services for discovery
4. **Bulk Subscribe:** Subscribe to multiple services at once
5. **Subscription Transfer:** Transfer subscription to another address

### Backward Compatibility
If upgrading, consider:
- Deploy new contract, migrate data
- Or use proxy pattern (adds complexity)
- Maintain old contract for existing subscriptions

## Conclusion

MicroSubs demonstrates that effective smart contracts don't need to be complex. By focusing on core functionality and following best practices, we achieve:

- ✅ Security through simplicity
- ✅ Gas efficiency through optimization
- ✅ Usability through clear interface
- ✅ Maintainability through clean code

The design choices prioritize these principles over feature richness, making MicroSubs an excellent foundation for learning or building upon.
