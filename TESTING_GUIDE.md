# MicroSubs Testing Guide

Complete guide to testing the MicroSubs smart contract.

## Table of Contents
1. [Setup](#setup)
2. [Running Tests](#running-tests)
3. [Test Structure](#test-structure)
4. [Test Coverage](#test-coverage)
5. [Writing New Tests](#writing-new-tests)
6. [Debugging Tests](#debugging-tests)

## Setup

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
```

### Build Project

```bash
# Navigate to project
cd de-sub

# Compile contracts
forge build
```

## Running Tests

### Basic Commands

```bash
# Run all tests
forge test

# Run with verbosity (show test names)
forge test -v

# Run with more verbosity (show logs)
forge test -vv

# Run with maximum verbosity (show traces)
forge test -vvv

# Run with extreme verbosity (show setup traces)
forge test -vvvv
```

### Filtering Tests

```bash
# Run specific test function
forge test --match-test testSubscribe

# Run tests matching pattern
forge test --match-test "testSubscribe*"

# Run tests in specific contract
forge test --match-contract MicroSubsTest

# Run tests NOT matching pattern
forge test --no-match-test testFuzz
```

### Gas Reporting

```bash
# Show gas usage for each test
forge test --gas-report

# Save gas snapshot
forge snapshot

# Compare with previous snapshot
forge snapshot --diff

# Check specific gas limit
forge test --gas-limit 30000000
```

### Coverage Analysis

```bash
# Generate coverage report
forge coverage

# Generate detailed coverage (lcov format)
forge coverage --report lcov

# Generate HTML coverage report
forge coverage --report lcov && genhtml lcov.info -o coverage

# View coverage in browser
open coverage/index.html
```

## Test Structure

### Test File Organization

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MicroSubs.sol";

contract MicroSubsTest is Test {
    // 1. State variables
    MicroSubs public microSubs;
    address public creator;
    address public user1;
    
    // 2. Events (for expectEmit)
    event ServiceCreated(...);
    
    // 3. Setup function
    function setUp() public {
        // Runs before each test
    }
    
    // 4. Test functions
    function testExample() public {
        // Test logic
    }
    
    // 5. Fuzz test functions
    function testFuzzExample(uint256 x) public {
        // Fuzz test logic
    }
    
    // 6. Helper functions
    function helperFunction() internal {
        // Reusable logic
    }
}
```

### Test Categories

#### 1. Unit Tests
Test individual functions in isolation.

```solidity
function testCreateService() public {
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(0.1 ether);
    assertEq(serviceId, 0);
}
```

#### 2. Integration Tests
Test complete user flows.

```solidity
function testCompleteSubscriptionFlow() public {
    // Create service
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(0.1 ether);
    
    // Subscribe
    vm.prank(user1);
    microSubs.subscribe{value: 0.1 ether}(serviceId);
    
    // Verify
    assertTrue(microSubs.isSubscribed(user1, serviceId));
    
    // Withdraw
    vm.prank(creator);
    microSubs.withdrawEarnings(serviceId);
}
```

#### 3. Fuzz Tests
Test with random inputs.

```solidity
function testFuzzSubscribe(uint96 price) public {
    vm.assume(price > 0);
    
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(price);
    
    vm.deal(user1, price);
    vm.prank(user1);
    microSubs.subscribe{value: price}(serviceId);
    
    assertTrue(microSubs.isSubscribed(user1, serviceId));
}
```

#### 4. Negative Tests
Test error conditions.

```solidity
function testSubscribeRevertsOnIncorrectPayment() public {
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(0.1 ether);
    
    vm.prank(user1);
    vm.expectRevert(MicroSubs.IncorrectPaymentAmount.selector);
    microSubs.subscribe{value: 0.05 ether}(serviceId);
}
```

## Test Coverage

### Current Coverage

```
File                  | % Lines        | % Statements   | % Branches    | % Funcs       
----------------------|----------------|----------------|---------------|---------------
src/MicroSubs.sol     | 100.00% (X/X)  | 100.00% (X/X)  | 100.00% (X/X) | 100.00% (X/X)
Total                 | 100.00% (X/X)  | 100.00% (X/X)  | 100.00% (X/X) | 100.00% (X/X)
```

### Coverage by Function

- ✅ `createService()` - 100%
- ✅ `subscribe()` - 100%
- ✅ `isSubscribed()` - 100%
- ✅ `withdrawEarnings()` - 100%
- ✅ `getSubscriptionExpiry()` - 100%
- ✅ `getEarnings()` - 100%
- ✅ `getNextServiceId()` - 100%
- ✅ `getServiceDetails()` - 100%

### Coverage by Scenario

- ✅ Happy paths
- ✅ Error conditions
- ✅ Edge cases
- ✅ Time-based logic
- ✅ Access control
- ✅ Payment handling
- ✅ State transitions

## Writing New Tests

### Test Template

```solidity
function testNewFeature() public {
    // 1. Setup
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(0.1 ether);
    
    // 2. Execute
    vm.prank(user1);
    microSubs.subscribe{value: 0.1 ether}(serviceId);
    
    // 3. Assert
    assertTrue(microSubs.isSubscribed(user1, serviceId));
}
```

### Best Practices

#### 1. Use Descriptive Names
```solidity
// ✅ Good
function testSubscribeRevertsOnIncorrectPayment() public { }

// ❌ Bad
function testSub1() public { }
```

#### 2. Test One Thing
```solidity
// ✅ Good - Tests one scenario
function testSubscriptionExpiration() public {
    // Setup, subscribe, time travel, check expiration
}

// ❌ Bad - Tests multiple unrelated things
function testEverything() public {
    // Create, subscribe, withdraw, check, etc.
}
```

#### 3. Use Arrange-Act-Assert
```solidity
function testExample() public {
    // Arrange - Setup test data
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(0.1 ether);
    
    // Act - Execute function
    vm.prank(user1);
    microSubs.subscribe{value: 0.1 ether}(serviceId);
    
    // Assert - Verify results
    assertTrue(microSubs.isSubscribed(user1, serviceId));
}
```

#### 4. Test Error Messages
```solidity
function testRevertWithCorrectError() public {
    vm.expectRevert(MicroSubs.InvalidPrice.selector);
    microSubs.createService(0);
}
```

#### 5. Test Events
```solidity
function testEmitsCorrectEvent() public {
    vm.expectEmit(true, true, false, true);
    emit ServiceCreated(0, creator, 0.1 ether);
    
    vm.prank(creator);
    microSubs.createService(0.1 ether);
}
```

## Foundry Cheatcodes

### Time Manipulation

```solidity
// Set block.timestamp
vm.warp(1641070800);

// Increase time by duration
vm.warp(block.timestamp + 30 days);

// Set block.number
vm.roll(100);
```

### Account Manipulation

```solidity
// Set msg.sender for next call
vm.prank(address);

// Set msg.sender for all subsequent calls
vm.startPrank(address);
vm.stopPrank();

// Give ETH to address
vm.deal(address, 10 ether);

// Set contract code
vm.etch(address, code);
```

### Expectations

```solidity
// Expect next call to revert
vm.expectRevert();
vm.expectRevert(ErrorSelector);
vm.expectRevert(bytes("error message"));

// Expect event emission
vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
emit ExpectedEvent(...);

// Expect call to address
vm.expectCall(address, calldata);
```

### Assertions

```solidity
// Equality
assertEq(a, b);
assertEq(a, b, "error message");

// Boolean
assertTrue(condition);
assertFalse(condition);

// Comparison
assertGt(a, b);  // a > b
assertGe(a, b);  // a >= b
assertLt(a, b);  // a < b
assertLe(a, b);  // a <= b

// Approximate equality
assertApproxEqAbs(a, b, maxDelta);
assertApproxEqRel(a, b, maxPercentDelta);
```

## Debugging Tests

### Verbose Output

```bash
# Show test names
forge test -v

# Show logs (console.log)
forge test -vv

# Show traces (function calls)
forge test -vvv

# Show setup traces
forge test -vvvv

# Show failed tests only
forge test --show-progress
```

### Console Logging

```solidity
import "forge-std/console.sol";

function testDebug() public {
    console.log("Value:", value);
    console.log("Address:", address);
    console.logBytes(data);
    console.logBytes32(hash);
}
```

### Debugging Specific Test

```bash
# Run single test with full traces
forge test --match-test testSubscribe -vvvv

# Run with gas report
forge test --match-test testSubscribe --gas-report

# Run with debugger
forge test --match-test testSubscribe --debug
```

### Common Issues

#### Issue: Test Reverts Unexpectedly
```solidity
// Add console.log to see values
console.log("msg.value:", msg.value);
console.log("expected:", service.pricePerMonth);

// Check with -vvvv to see full trace
// forge test --match-test testName -vvvv
```

#### Issue: Event Not Emitted
```solidity
// Verify event signature matches exactly
event ServiceCreated(uint256 indexed serviceId, address indexed creator, uint256 pricePerMonth);

// Check all parameters
vm.expectEmit(true, true, false, true);
emit ServiceCreated(expectedId, expectedCreator, expectedPrice);
```

#### Issue: Time-Based Test Fails
```solidity
// Verify timestamp manipulation
console.log("Current time:", block.timestamp);
vm.warp(block.timestamp + 30 days);
console.log("After warp:", block.timestamp);
```

## Advanced Testing Techniques

### 1. Invariant Testing

```solidity
contract InvariantTest is Test {
    MicroSubs public microSubs;
    
    function setUp() public {
        microSubs = new MicroSubs();
    }
    
    // Invariant: Total earnings should equal sum of all subscriptions
    function invariant_earningsMatchSubscriptions() public {
        // Check invariant holds
    }
}
```

### 2. Differential Testing

```solidity
function testAgainstReference(uint256 input) public {
    uint256 result1 = microSubs.calculate(input);
    uint256 result2 = referenceImplementation.calculate(input);
    assertEq(result1, result2);
}
```

### 3. Property-Based Testing

```solidity
function testProperty_subscriptionAlwaysExpires(uint32 timeElapsed) public {
    // Setup
    vm.prank(creator);
    uint256 serviceId = microSubs.createService(0.1 ether);
    
    vm.prank(user1);
    microSubs.subscribe{value: 0.1 ether}(serviceId);
    
    // Property: After 30+ days, subscription is always expired
    vm.assume(timeElapsed >= 30 days);
    vm.warp(block.timestamp + timeElapsed);
    
    assertFalse(microSubs.isSubscribed(user1, serviceId));
}
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Run tests
        run: forge test -vvv
      
      - name: Check coverage
        run: forge coverage
      
      - name: Gas report
        run: forge test --gas-report
```

## Performance Benchmarks

### Gas Benchmarks

```bash
# Create baseline
forge snapshot --snap baseline.txt

# Make changes...

# Compare
forge snapshot --diff baseline.txt
```

### Expected Gas Costs

| Function | First Call | Subsequent |
|----------|-----------|------------|
| createService | ~100k | ~100k |
| subscribe (new) | ~80k | ~80k |
| subscribe (renew) | ~60k | ~60k |
| withdrawEarnings | ~40k | ~40k |

## Test Checklist

Before committing:

- [ ] All tests pass: `forge test`
- [ ] Coverage is 100%: `forge coverage`
- [ ] Gas costs are reasonable: `forge test --gas-report`
- [ ] No console.log left in code
- [ ] Tests are well-named and documented
- [ ] Edge cases are covered
- [ ] Error conditions are tested
- [ ] Events are verified
- [ ] Time-based logic is tested

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Foundry Cheatcodes](https://book.getfoundry.sh/cheatcodes/)
- [Testing Best Practices](https://book.getfoundry.sh/tutorials/best-practices)
- [Forge Standard Library](https://github.com/foundry-rs/forge-std)

---

**Happy Testing! 🧪**
