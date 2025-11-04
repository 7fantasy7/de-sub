// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MicroSubs.sol";

/**
 * @title Interact Script
 * @notice Demonstrates complete interaction flow with MicroSubs contract
 * @dev Run with: forge script script/Interact.s.sol --rpc-url <RPC_URL> --broadcast
 */
contract InteractScript is Script {
    MicroSubs public microSubs;
    
    address public creator;
    address public user1;
    address public user2;
    
    function setUp() public {
        // Load contract address from environment or use deployed address
        address contractAddress = vm.envAddress("MICROSUBS_ADDRESS");
        microSubs = MicroSubs(contractAddress);
        
        // Setup test accounts
        creator = vm.addr(1);
        user1 = vm.addr(2);
        user2 = vm.addr(3);
    }
    
    function run() public {
        console.log("=== MicroSubs Interaction Demo ===\n");
        
        // Demo 1: Create services
        console.log("1. Creating services...");
        uint256 service1 = createService(creator, 0.1 ether, "Premium Newsletter");
        uint256 service2 = createService(creator, 0.05 ether, "Basic Newsletter");
        
        // Demo 2: Users subscribe
        console.log("\n2. Users subscribing...");
        subscribe(user1, service1, 0.1 ether);
        subscribe(user2, service2, 0.05 ether);
        subscribe(user1, service2, 0.05 ether); // User1 subscribes to both
        
        // Demo 3: Check subscriptions
        console.log("\n3. Checking subscription status...");
        checkSubscription(user1, service1);
        checkSubscription(user1, service2);
        checkSubscription(user2, service1);
        checkSubscription(user2, service2);
        
        // Demo 4: Check earnings
        console.log("\n4. Checking creator earnings...");
        checkEarnings(service1);
        checkEarnings(service2);
        
        // Demo 5: Withdraw earnings
        console.log("\n5. Creator withdrawing earnings...");
        withdrawEarnings(creator, service1);
        withdrawEarnings(creator, service2);
        
        console.log("\n=== Demo Complete ===");
    }
    
    function createService(address _creator, uint256 price, string memory name) internal returns (uint256) {
        vm.startBroadcast(_creator);
        
        uint256 serviceId = microSubs.createService(price);
        
        vm.stopBroadcast();
        
        console.log("  Created service:", name);
        console.log("  Service ID:", serviceId);
        console.log("  Price:", price / 1e18, "ETH");
        console.log("  Creator:", _creator);
        
        return serviceId;
    }
    
    function subscribe(address user, uint256 serviceId, uint256 price) internal {
        vm.startBroadcast(user);
        
        microSubs.subscribe{value: price}(serviceId);
        
        vm.stopBroadcast();
        
        uint256 expiry = microSubs.getSubscriptionExpiry(user, serviceId);
        
        console.log("  User", user, "subscribed to service", serviceId);
        console.log("  Expiry:", expiry);
        console.log("  Days remaining:", (expiry - block.timestamp) / 1 days);
    }
    
    function checkSubscription(address user, uint256 serviceId) internal view {
        bool isActive = microSubs.isSubscribed(user, serviceId);
        uint256 expiry = microSubs.getSubscriptionExpiry(user, serviceId);
        
        console.log("  User:", user);
        console.log("  Service:", serviceId);
        console.log("  Active:", isActive);
        if (expiry > 0) {
            console.log("  Expiry:", expiry);
            if (isActive) {
                console.log("  Days remaining:", (expiry - block.timestamp) / 1 days);
            }
        }
        console.log("");
    }
    
    function checkEarnings(uint256 serviceId) internal view {
        uint256 earnings = microSubs.getEarnings(serviceId);
        (address serviceCreator, uint256 price,) = microSubs.getServiceDetails(serviceId);
        
        console.log("  Service ID:", serviceId);
        console.log("  Creator:", serviceCreator);
        console.log("  Price:", price / 1e18, "ETH");
        console.log("  Earnings:", earnings / 1e18, "ETH");
        console.log("  Subscribers:", earnings / price);
        console.log("");
    }
    
    function withdrawEarnings(address _creator, uint256 serviceId) internal {
        uint256 balanceBefore = _creator.balance;
        uint256 earnings = microSubs.getEarnings(serviceId);
        
        vm.startBroadcast(_creator);
        
        microSubs.withdrawEarnings(serviceId);
        
        vm.stopBroadcast();
        
        uint256 balanceAfter = _creator.balance;
        
        console.log("  Service ID:", serviceId);
        console.log("  Amount withdrawn:", earnings / 1e18, "ETH");
        console.log("  Creator balance before:", balanceBefore / 1e18, "ETH");
        console.log("  Creator balance after:", balanceAfter / 1e18, "ETH");
        console.log("");
    }
}

/**
 * @title Demo Script
 * @notice Quick demo showing subscription expiration
 */
contract DemoExpirationScript is Script {
    MicroSubs public microSubs;
    
    function run() public {
        address contractAddress = vm.envAddress("MICROSUBS_ADDRESS");
        microSubs = MicroSubs(contractAddress);
        
        address creator = vm.addr(1);
        address user = vm.addr(2);
        
        console.log("=== Subscription Expiration Demo ===\n");
        
        // Create service
        vm.startBroadcast(creator);
        uint256 serviceId = microSubs.createService(0.1 ether);
        vm.stopBroadcast();
        
        console.log("Service created with ID:", serviceId);
        
        // Subscribe
        vm.startBroadcast(user);
        microSubs.subscribe{value: 0.1 ether}(serviceId);
        vm.stopBroadcast();
        
        console.log("User subscribed at block:", block.timestamp);
        console.log("Subscription active:", microSubs.isSubscribed(user, serviceId));
        
        // Simulate time passing (15 days)
        vm.warp(block.timestamp + 15 days);
        console.log("\n--- 15 days later ---");
        console.log("Current block:", block.timestamp);
        console.log("Subscription active:", microSubs.isSubscribed(user, serviceId));
        
        // Simulate time passing (30 days total)
        vm.warp(block.timestamp + 15 days);
        console.log("\n--- 30 days later (expired) ---");
        console.log("Current block:", block.timestamp);
        console.log("Subscription active:", microSubs.isSubscribed(user, serviceId));
        
        // Renew subscription
        vm.startBroadcast(user);
        microSubs.subscribe{value: 0.1 ether}(serviceId);
        vm.stopBroadcast();
        
        console.log("\n--- User renewed subscription ---");
        console.log("Subscription active:", microSubs.isSubscribed(user, serviceId));
        uint256 newExpiry = microSubs.getSubscriptionExpiry(user, serviceId);
        console.log("New expiry:", newExpiry);
        console.log("Days until expiry:", (newExpiry - block.timestamp) / 1 days);
    }
}
