// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MicroSubs.sol";

contract MicroSubsTest is Test {
    MicroSubs public microSubs;
    
    address public creator = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    
    uint256 public constant SERVICE_PRICE = 0.1 ether;
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    
    event ServiceCreated(uint256 indexed serviceId, address indexed creator, uint256 pricePerMonth);
    event UserSubscribed(uint256 indexed serviceId, address indexed user, uint256 expiry);
    event EarningsWithdrawn(uint256 indexed serviceId, address indexed creator, uint256 amount);
    
    function setUp() public {
        microSubs = new MicroSubs();
        
        // Fund test accounts
        vm.deal(creator, 10 ether);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    /*//////////////////////////////////////////////////////////////
                        CREATE SERVICE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testCreateService() public {
        vm.startPrank(creator);
        
        vm.expectEmit(true, true, false, true);
        emit ServiceCreated(0, creator, SERVICE_PRICE);
        
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        assertEq(serviceId, 0, "First service ID should be 0");
        
        (address serviceCreator, uint256 price, bool exists) = microSubs.getServiceDetails(serviceId);
        assertEq(serviceCreator, creator, "Creator should match");
        assertEq(price, SERVICE_PRICE, "Price should match");
        assertTrue(exists, "Service should exist");
        
        vm.stopPrank();
    }
    
    function testCreateMultipleServices() public {
        vm.startPrank(creator);
        
        uint256 serviceId1 = microSubs.createService(0.1 ether);
        uint256 serviceId2 = microSubs.createService(0.2 ether);
        uint256 serviceId3 = microSubs.createService(0.3 ether);
        
        assertEq(serviceId1, 0, "First service ID should be 0");
        assertEq(serviceId2, 1, "Second service ID should be 1");
        assertEq(serviceId3, 2, "Third service ID should be 2");
        
        vm.stopPrank();
    }
    
    function testCreateServiceRevertsOnZeroPrice() public {
        vm.startPrank(creator);
        
        vm.expectRevert(MicroSubs.InvalidPrice.selector);
        microSubs.createService(0);
        
        vm.stopPrank();
    }
    
    function testGetNextServiceId() public {
        assertEq(microSubs.getNextServiceId(), 0, "Initial next service ID should be 0");
        
        vm.prank(creator);
        microSubs.createService(SERVICE_PRICE);
        
        assertEq(microSubs.getNextServiceId(), 1, "Next service ID should be 1 after creating one service");
    }
    
    /*//////////////////////////////////////////////////////////////
                        SUBSCRIPTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testSubscribe() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // Subscribe
        vm.startPrank(user1);
        
        uint256 expectedExpiry = block.timestamp + SUBSCRIPTION_DURATION;
        
        vm.expectEmit(true, true, false, true);
        emit UserSubscribed(serviceId, user1, expectedExpiry);
        
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        assertTrue(microSubs.isSubscribed(user1, serviceId), "User should be subscribed");
        assertEq(microSubs.getSubscriptionExpiry(user1, serviceId), expectedExpiry, "Expiry should match");
        
        vm.stopPrank();
    }
    
    function testSubscribeMultipleUsers() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // User 1 subscribes
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // User 2 subscribes
        vm.prank(user2);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        assertTrue(microSubs.isSubscribed(user1, serviceId), "User1 should be subscribed");
        assertTrue(microSubs.isSubscribed(user2, serviceId), "User2 should be subscribed");
    }
    
    function testSubscribeRevertsOnNonExistentService() public {
        vm.startPrank(user1);
        
        vm.expectRevert(MicroSubs.ServiceDoesNotExist.selector);
        microSubs.subscribe{value: SERVICE_PRICE}(999);
        
        vm.stopPrank();
    }
    
    function testSubscribeRevertsOnIncorrectPayment() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // Try to subscribe with wrong amount
        vm.startPrank(user1);
        
        vm.expectRevert(MicroSubs.IncorrectPaymentAmount.selector);
        microSubs.subscribe{value: SERVICE_PRICE - 0.01 ether}(serviceId);
        
        vm.expectRevert(MicroSubs.IncorrectPaymentAmount.selector);
        microSubs.subscribe{value: SERVICE_PRICE + 0.01 ether}(serviceId);
        
        vm.stopPrank();
    }
    
    function testSubscriptionExtension() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // First subscription
        vm.startPrank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        uint256 firstExpiry = microSubs.getSubscriptionExpiry(user1, serviceId);
        
        // Fast forward 15 days (still active)
        vm.warp(block.timestamp + 15 days);
        assertTrue(microSubs.isSubscribed(user1, serviceId), "Should still be subscribed");
        
        // Subscribe again to extend
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        uint256 secondExpiry = microSubs.getSubscriptionExpiry(user1, serviceId);
        
        // New expiry should be 30 days from the first expiry
        assertEq(secondExpiry, firstExpiry + SUBSCRIPTION_DURATION, "Expiry should extend from previous expiry");
        
        vm.stopPrank();
    }
    
    function testSubscriptionAfterExpiry() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // First subscription
        vm.startPrank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 31 days);
        assertFalse(microSubs.isSubscribed(user1, serviceId), "Should not be subscribed after expiry");
        
        // Subscribe again
        uint256 newSubscribeTime = block.timestamp;
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        uint256 newExpiry = microSubs.getSubscriptionExpiry(user1, serviceId);
        assertEq(newExpiry, newSubscribeTime + SUBSCRIPTION_DURATION, "New subscription should start from current time");
        
        vm.stopPrank();
    }
    
    /*//////////////////////////////////////////////////////////////
                        EXPIRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testSubscriptionExpiration() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // Subscribe
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // Check subscription is active
        assertTrue(microSubs.isSubscribed(user1, serviceId), "Should be subscribed initially");
        
        // Fast forward to just before expiry
        vm.warp(block.timestamp + SUBSCRIPTION_DURATION - 1);
        assertTrue(microSubs.isSubscribed(user1, serviceId), "Should still be subscribed 1 second before expiry");
        
        // Fast forward to exactly at expiry
        vm.warp(block.timestamp + 1);
        assertFalse(microSubs.isSubscribed(user1, serviceId), "Should not be subscribed at expiry");
        
        // Fast forward past expiry
        vm.warp(block.timestamp + 1 days);
        assertFalse(microSubs.isSubscribed(user1, serviceId), "Should not be subscribed after expiry");
    }
    
    function testIsSubscribedForNeverSubscribedUser() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // Check user who never subscribed
        assertFalse(microSubs.isSubscribed(user1, serviceId), "User who never subscribed should return false");
    }
    
    /*//////////////////////////////////////////////////////////////
                        EARNINGS & WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testEarningsAccumulation() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        assertEq(microSubs.getEarnings(serviceId), 0, "Initial earnings should be 0");
        
        // User 1 subscribes
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        assertEq(microSubs.getEarnings(serviceId), SERVICE_PRICE, "Earnings should be SERVICE_PRICE");
        
        // User 2 subscribes
        vm.prank(user2);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        assertEq(microSubs.getEarnings(serviceId), SERVICE_PRICE * 2, "Earnings should be SERVICE_PRICE * 2");
    }
    
    function testWithdrawEarnings() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // Users subscribe
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        vm.prank(user2);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        uint256 totalEarnings = SERVICE_PRICE * 2;
        assertEq(microSubs.getEarnings(serviceId), totalEarnings, "Earnings should be accumulated");
        
        // Withdraw earnings
        uint256 creatorBalanceBefore = creator.balance;
        
        vm.startPrank(creator);
        
        vm.expectEmit(true, true, false, true);
        emit EarningsWithdrawn(serviceId, creator, totalEarnings);
        
        microSubs.withdrawEarnings(serviceId);
        
        vm.stopPrank();
        
        assertEq(creator.balance, creatorBalanceBefore + totalEarnings, "Creator should receive earnings");
        assertEq(microSubs.getEarnings(serviceId), 0, "Earnings should be reset to 0");
    }
    
    function testWithdrawEarningsRevertsOnNonCreator() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // User subscribes
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // Try to withdraw as non-creator
        vm.startPrank(user2);
        
        vm.expectRevert(MicroSubs.NotServiceCreator.selector);
        microSubs.withdrawEarnings(serviceId);
        
        vm.stopPrank();
    }
    
    function testWithdrawEarningsRevertsOnZeroEarnings() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // Try to withdraw with no earnings
        vm.startPrank(creator);
        
        vm.expectRevert(MicroSubs.NoEarningsToWithdraw.selector);
        microSubs.withdrawEarnings(serviceId);
        
        vm.stopPrank();
    }
    
    function testWithdrawEarningsRevertsOnNonExistentService() public {
        vm.startPrank(creator);
        
        vm.expectRevert(MicroSubs.ServiceDoesNotExist.selector);
        microSubs.withdrawEarnings(999);
        
        vm.stopPrank();
    }
    
    function testMultipleWithdrawals() public {
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // First batch of subscriptions
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // First withdrawal
        vm.prank(creator);
        microSubs.withdrawEarnings(serviceId);
        
        assertEq(microSubs.getEarnings(serviceId), 0, "Earnings should be 0 after withdrawal");
        
        // Second batch of subscriptions
        vm.prank(user2);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        assertEq(microSubs.getEarnings(serviceId), SERVICE_PRICE, "New earnings should accumulate");
        
        // Second withdrawal
        vm.prank(creator);
        microSubs.withdrawEarnings(serviceId);
        
        assertEq(microSubs.getEarnings(serviceId), 0, "Earnings should be 0 after second withdrawal");
    }
    
    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testCompleteSubscriptionFlow() public {
        // Creator creates service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        // User subscribes
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // Verify subscription is active
        assertTrue(microSubs.isSubscribed(user1, serviceId), "User should be subscribed");
        
        // Fast forward 15 days
        vm.warp(block.timestamp + 15 days);
        assertTrue(microSubs.isSubscribed(user1, serviceId), "User should still be subscribed");
        
        // Fast forward to expiry
        vm.warp(block.timestamp + 16 days);
        assertFalse(microSubs.isSubscribed(user1, serviceId), "User should not be subscribed after expiry");
        
        // Creator withdraws earnings
        uint256 creatorBalanceBefore = creator.balance;
        vm.prank(creator);
        microSubs.withdrawEarnings(serviceId);
        
        assertEq(creator.balance, creatorBalanceBefore + SERVICE_PRICE, "Creator should receive payment");
    }
    
    function testMultipleServicesAndUsers() public {
        // Create multiple services
        vm.startPrank(creator);
        uint256 service1 = microSubs.createService(0.1 ether);
        uint256 service2 = microSubs.createService(0.2 ether);
        vm.stopPrank();
        
        // User1 subscribes to service1
        vm.prank(user1);
        microSubs.subscribe{value: 0.1 ether}(service1);
        
        // User2 subscribes to service2
        vm.prank(user2);
        microSubs.subscribe{value: 0.2 ether}(service2);
        
        // User1 subscribes to service2
        vm.prank(user1);
        microSubs.subscribe{value: 0.2 ether}(service2);
        
        // Verify subscriptions
        assertTrue(microSubs.isSubscribed(user1, service1), "User1 should be subscribed to service1");
        assertFalse(microSubs.isSubscribed(user2, service1), "User2 should not be subscribed to service1");
        assertTrue(microSubs.isSubscribed(user1, service2), "User1 should be subscribed to service2");
        assertTrue(microSubs.isSubscribed(user2, service2), "User2 should be subscribed to service2");
        
        // Verify earnings
        assertEq(microSubs.getEarnings(service1), 0.1 ether, "Service1 earnings should be 0.1 ether");
        assertEq(microSubs.getEarnings(service2), 0.4 ether, "Service2 earnings should be 0.4 ether");
    }
    
    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testFuzzCreateService(uint256 price) public {
        vm.assume(price > 0);
        vm.assume(price < type(uint128).max); // Reasonable upper bound
        
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(price);
        
        (, uint256 servicePrice, bool exists) = microSubs.getServiceDetails(serviceId);
        assertEq(servicePrice, price, "Service price should match");
        assertTrue(exists, "Service should exist");
    }
    
    function testFuzzSubscribe(uint96 price) public {
        vm.assume(price > 0);
        
        // Create service
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(price);
        
        // Fund user and subscribe
        vm.deal(user1, price);
        vm.prank(user1);
        microSubs.subscribe{value: price}(serviceId);
        
        assertTrue(microSubs.isSubscribed(user1, serviceId), "User should be subscribed");
        assertEq(microSubs.getEarnings(serviceId), price, "Earnings should match price");
    }
    
    function testFuzzTimeTravel(uint32 timeElapsed) public {
        // Create service and subscribe
        vm.prank(creator);
        uint256 serviceId = microSubs.createService(SERVICE_PRICE);
        
        vm.prank(user1);
        microSubs.subscribe{value: SERVICE_PRICE}(serviceId);
        
        // Time travel
        vm.warp(block.timestamp + timeElapsed);
        
        // Check subscription status
        bool shouldBeSubscribed = timeElapsed < SUBSCRIPTION_DURATION;
        assertEq(
            microSubs.isSubscribed(user1, serviceId), 
            shouldBeSubscribed, 
            "Subscription status should match expected"
        );
    }
}
