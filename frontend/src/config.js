// MicroSubs Contract Configuration
// Update these values after deploying to testnet

export const CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000"; // UPDATE THIS
export const SEPOLIA_CHAIN_ID = "0xaa36a7"; // 11155111 in hex

export const CONTRACT_ABI = [
  "function createService(uint256 price) external returns (uint256 serviceId)",
  "function subscribe(uint256 serviceId) external payable",
  "function isSubscribed(address user, uint256 serviceId) external view returns (bool)",
  "function withdrawEarnings(uint256 serviceId) external",
  "function updateServicePrice(uint256 serviceId, uint256 newPrice) external",
  "function pauseService(uint256 serviceId) external",
  "function unpauseService(uint256 serviceId) external",
  "function getServiceInfo(uint256 serviceId) external view returns (address creator, uint256 pricePerMonth, bool exists, bool paused, uint256 subscriberCount)",
  "function getSubscriptionExpiry(address user, uint256 serviceId) external view returns (uint256)",
  "function getEarnings(uint256 serviceId) external view returns (uint256)",
  "function getNextServiceId() external view returns (uint256)",
  "event ServiceCreated(uint256 indexed serviceId, address indexed creator, uint256 pricePerMonth)",
  "event UserSubscribed(uint256 indexed serviceId, address indexed user, uint256 expiry)",
  "event EarningsWithdrawn(uint256 indexed serviceId, address indexed creator, uint256 amount)",
  "event ServicePriceUpdated(uint256 indexed serviceId, uint256 oldPrice, uint256 newPrice)",
  "event ServicePaused(uint256 indexed serviceId)",
  "event ServiceUnpaused(uint256 indexed serviceId)"
];
