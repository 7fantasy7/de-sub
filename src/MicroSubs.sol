// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MicroSubs - Smart Subscription Manager
 * @notice A decentralized subscription management system where creators can offer services
 *         and users can subscribe with automatic expiration based on timestamps
 * @dev All subscriptions are 30-day periods from the time of subscription
 */
contract MicroSubs {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error ServiceDoesNotExist();
    error InvalidPrice();
    error IncorrectPaymentAmount();
    error NotServiceCreator();
    error NoEarningsToWithdraw();
    error TransferFailed();
    error SubscriptionExpired();
    error ServicePaused();
    error CannotChangePriceWithActiveSubscribers();
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event ServiceCreated(uint256 indexed serviceId, address indexed creator, uint256 pricePerMonth);
    event UserSubscribed(uint256 indexed serviceId, address indexed user, uint256 expiry);
    event EarningsWithdrawn(uint256 indexed serviceId, address indexed creator, uint256 amount);
    event ServicePriceUpdated(uint256 indexed serviceId, uint256 oldPrice, uint256 newPrice);
    event ServicePaused(uint256 indexed serviceId);
    event ServiceUnpaused(uint256 indexed serviceId);
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Duration of a subscription in seconds (30 days)
    uint256 public constant SUBSCRIPTION_DURATION = 30 days;
    
    /// @notice Counter for service IDs
    uint256 private _nextServiceId;
    
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Represents a service offered by a creator
    struct Service {
        address creator;
        uint256 pricePerMonth;
        bool exists;
        bool paused;
        uint256 subscriberCount;
    }
    
    /// @notice Represents a user's subscription to a service
    struct Subscription {
        uint256 expiry;
    }
    
    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Maps service ID to Service details
    mapping(uint256 => Service) public services;
    
    /// @notice Maps service ID => user address => Subscription details
    mapping(uint256 => mapping(address => Subscription)) public subscriptions;
    
    /// @notice Maps service ID => accumulated earnings for the creator
    mapping(uint256 => uint256) public earnings;
    
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Creates a new service with a monthly subscription price
     * @param price The price in wei for a 30-day subscription
     * @return serviceId The ID of the newly created service
     * @dev Price must be greater than 0 to prevent free services (can be modified if needed)
     */
    function createService(uint256 price) external returns (uint256 serviceId) {
        if (price == 0) revert InvalidPrice();
        
        serviceId = _nextServiceId++;
        
        services[serviceId] = Service({
            creator: msg.sender,
            pricePerMonth: price,
            exists: true,
            paused: false,
            subscriberCount: 0
        });
        
        emit ServiceCreated(serviceId, msg.sender, price);
    }
    
    /**
     * @notice Subscribe to a service for 30 days
     * @param serviceId The ID of the service to subscribe to
     * @dev Requires exact payment amount. Extends subscription if already active.
     */
    function subscribe(uint256 serviceId) external payable {
        Service storage service = services[serviceId];
        
        if (!service.exists) revert ServiceDoesNotExist();
        if (service.paused) revert ServicePaused();
        if (msg.value != service.pricePerMonth) revert IncorrectPaymentAmount();
        
        Subscription storage subscription = subscriptions[serviceId][msg.sender];
        
        // Track new subscribers
        bool isNewSubscriber = subscription.expiry <= block.timestamp;
        
        // If subscription is still active, extend from current expiry
        // Otherwise, start from current timestamp
        uint256 startTime = subscription.expiry > block.timestamp 
            ? subscription.expiry 
            : block.timestamp;
        
        subscription.expiry = startTime + SUBSCRIPTION_DURATION;
        
        // Increment subscriber count for new subscribers
        if (isNewSubscriber) {
            service.subscriberCount++;
        }
        
        // Add payment to creator's earnings
        earnings[serviceId] += msg.value;
        
        emit UserSubscribed(serviceId, msg.sender, subscription.expiry);
    }
    
    /**
     * @notice Check if a user has an active subscription to a service
     * @param user The address of the user to check
     * @param serviceId The ID of the service
     * @return bool True if the user has an active subscription, false otherwise
     */
    function isSubscribed(address user, uint256 serviceId) external view returns (bool) {
        return subscriptions[serviceId][user].expiry > block.timestamp;
    }
    
    /**
     * @notice Allows service creator to withdraw accumulated earnings
     * @param serviceId The ID of the service to withdraw earnings from
     * @dev Only the service creator can withdraw. Transfers all accumulated earnings.
     */
    function withdrawEarnings(uint256 serviceId) external {
        Service storage service = services[serviceId];
        
        if (!service.exists) revert ServiceDoesNotExist();
        if (service.creator != msg.sender) revert NotServiceCreator();
        
        uint256 amount = earnings[serviceId];
        if (amount == 0) revert NoEarningsToWithdraw();
        
        // Reset earnings before transfer (CEI pattern)
        earnings[serviceId] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit EarningsWithdrawn(serviceId, msg.sender, amount);
    }
    
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Get the expiry timestamp of a user's subscription
     * @param user The address of the user
     * @param serviceId The ID of the service
     * @return uint256 The expiry timestamp (0 if never subscribed)
     */
    function getSubscriptionExpiry(address user, uint256 serviceId) external view returns (uint256) {
        return subscriptions[serviceId][user].expiry;
    }
    
    /**
     * @notice Get the accumulated earnings for a service
     * @param serviceId The ID of the service
     * @return uint256 The amount of earnings in wei
     */
    function getEarnings(uint256 serviceId) external view returns (uint256) {
        return earnings[serviceId];
    }
    
    /**
     * @notice Get the next service ID that will be assigned
     * @return uint256 The next service ID
     */
    function getNextServiceId() external view returns (uint256) {
        return _nextServiceId;
    }
    
    /**
     * @notice Get complete service details
     * @param serviceId The ID of the service
     * @return creator The address of the service creator
     * @return pricePerMonth The monthly subscription price in wei
     * @return exists Whether the service exists
     */
    function getServiceDetails(uint256 serviceId) 
        external 
        view 
        returns (address creator, uint256 pricePerMonth, bool exists) 
    {
        Service storage service = services[serviceId];
        return (service.creator, service.pricePerMonth, service.exists);
    }
    
    /**
     * @notice Get complete service information including pause status and subscriber count
     * @param serviceId The ID of the service
     * @return creator The address of the service creator
     * @return pricePerMonth The monthly subscription price in wei
     * @return exists Whether the service exists
     * @return paused Whether the service is paused
     * @return subscriberCount The number of active subscribers
     */
    function getServiceInfo(uint256 serviceId)
        external
        view
        returns (
            address creator,
            uint256 pricePerMonth,
            bool exists,
            bool paused,
            uint256 subscriberCount
        )
    {
        Service storage service = services[serviceId];
        return (
            service.creator,
            service.pricePerMonth,
            service.exists,
            service.paused,
            service.subscriberCount
        );
    }
    
    /*//////////////////////////////////////////////////////////////
                        CREATOR MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Update the price of a service
     * @param serviceId The ID of the service
     * @param newPrice The new price in wei
     * @dev Only creator can update. Price changes don't affect existing subscriptions.
     */
    function updateServicePrice(uint256 serviceId, uint256 newPrice) external {
        Service storage service = services[serviceId];
        
        if (!service.exists) revert ServiceDoesNotExist();
        if (service.creator != msg.sender) revert NotServiceCreator();
        if (newPrice == 0) revert InvalidPrice();
        
        uint256 oldPrice = service.pricePerMonth;
        service.pricePerMonth = newPrice;
        
        emit ServicePriceUpdated(serviceId, oldPrice, newPrice);
    }
    
    /**
     * @notice Pause a service to prevent new subscriptions
     * @param serviceId The ID of the service to pause
     * @dev Only creator can pause. Existing subscriptions remain valid.
     */
    function pauseService(uint256 serviceId) external {
        Service storage service = services[serviceId];
        
        if (!service.exists) revert ServiceDoesNotExist();
        if (service.creator != msg.sender) revert NotServiceCreator();
        
        service.paused = true;
        
        emit ServicePaused(serviceId);
    }
    
    /**
     * @notice Unpause a service to allow new subscriptions
     * @param serviceId The ID of the service to unpause
     * @dev Only creator can unpause.
     */
    function unpauseService(uint256 serviceId) external {
        Service storage service = services[serviceId];
        
        if (!service.exists) revert ServiceDoesNotExist();
        if (service.creator != msg.sender) revert NotServiceCreator();
        
        service.paused = false;
        
        emit ServiceUnpaused(serviceId);
    }
}
