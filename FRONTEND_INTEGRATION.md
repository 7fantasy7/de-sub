# Frontend Integration Guide

This guide shows how to integrate MicroSubs into a web application using ethers.js or web3.js.

## Setup

### Install Dependencies

```bash
npm install ethers
# or
npm install web3
```

### Contract ABI

Export the ABI after compiling:

```bash
forge build
cat out/MicroSubs.sol/MicroSubs.json | jq .abi > MicroSubs.abi.json
```

## ethers.js Integration

### 1. Connect to Contract

```javascript
import { ethers } from 'ethers';
import MicroSubsABI from './MicroSubs.abi.json';

const CONTRACT_ADDRESS = '0x...'; // Your deployed contract address

// Connect to MetaMask
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

// Create contract instance
const microSubs = new ethers.Contract(
  CONTRACT_ADDRESS,
  MicroSubsABI,
  signer
);
```

### 2. Create a Service

```javascript
async function createService(priceInEth) {
  try {
    const priceInWei = ethers.parseEther(priceInEth.toString());
    
    const tx = await microSubs.createService(priceInWei);
    console.log('Transaction sent:', tx.hash);
    
    const receipt = await tx.wait();
    console.log('Transaction confirmed:', receipt);
    
    // Extract service ID from event
    const event = receipt.logs.find(log => {
      try {
        const parsed = microSubs.interface.parseLog(log);
        return parsed.name === 'ServiceCreated';
      } catch {
        return false;
      }
    });
    
    if (event) {
      const parsed = microSubs.interface.parseLog(event);
      const serviceId = parsed.args.serviceId;
      console.log('Service created with ID:', serviceId.toString());
      return serviceId;
    }
  } catch (error) {
    console.error('Error creating service:', error);
    throw error;
  }
}

// Usage
const serviceId = await createService(0.1); // 0.1 ETH per month
```

### 3. Subscribe to a Service

```javascript
async function subscribe(serviceId, priceInEth) {
  try {
    const priceInWei = ethers.parseEther(priceInEth.toString());
    
    const tx = await microSubs.subscribe(serviceId, {
      value: priceInWei
    });
    
    console.log('Subscription transaction sent:', tx.hash);
    const receipt = await tx.wait();
    console.log('Subscription confirmed:', receipt);
    
    return receipt;
  } catch (error) {
    console.error('Error subscribing:', error);
    throw error;
  }
}

// Usage
await subscribe(0, 0.1); // Subscribe to service 0 with 0.1 ETH
```

### 4. Check Subscription Status

```javascript
async function checkSubscription(userAddress, serviceId) {
  try {
    const isSubscribed = await microSubs.isSubscribed(userAddress, serviceId);
    
    if (isSubscribed) {
      const expiry = await microSubs.getSubscriptionExpiry(userAddress, serviceId);
      const expiryDate = new Date(Number(expiry) * 1000);
      const daysRemaining = Math.ceil((expiryDate - new Date()) / (1000 * 60 * 60 * 24));
      
      return {
        isSubscribed: true,
        expiry: expiryDate,
        daysRemaining
      };
    }
    
    return { isSubscribed: false };
  } catch (error) {
    console.error('Error checking subscription:', error);
    throw error;
  }
}

// Usage
const status = await checkSubscription('0x...', 0);
console.log('Subscription status:', status);
```

### 5. Get Service Details

```javascript
async function getServiceDetails(serviceId) {
  try {
    const [creator, pricePerMonth, exists] = await microSubs.getServiceDetails(serviceId);
    
    if (!exists) {
      return null;
    }
    
    return {
      serviceId,
      creator,
      pricePerMonth: ethers.formatEther(pricePerMonth),
      exists
    };
  } catch (error) {
    console.error('Error getting service details:', error);
    throw error;
  }
}

// Usage
const service = await getServiceDetails(0);
console.log('Service:', service);
```

### 6. Withdraw Earnings

```javascript
async function withdrawEarnings(serviceId) {
  try {
    // Check earnings first
    const earnings = await microSubs.getEarnings(serviceId);
    console.log('Earnings to withdraw:', ethers.formatEther(earnings), 'ETH');
    
    if (earnings === 0n) {
      throw new Error('No earnings to withdraw');
    }
    
    const tx = await microSubs.withdrawEarnings(serviceId);
    console.log('Withdrawal transaction sent:', tx.hash);
    
    const receipt = await tx.wait();
    console.log('Withdrawal confirmed:', receipt);
    
    return receipt;
  } catch (error) {
    console.error('Error withdrawing earnings:', error);
    throw error;
  }
}

// Usage
await withdrawEarnings(0);
```

### 7. Listen to Events

```javascript
// Listen for new services
microSubs.on('ServiceCreated', (serviceId, creator, pricePerMonth, event) => {
  console.log('New service created:', {
    serviceId: serviceId.toString(),
    creator,
    pricePerMonth: ethers.formatEther(pricePerMonth)
  });
});

// Listen for new subscriptions
microSubs.on('UserSubscribed', (serviceId, user, expiry, event) => {
  console.log('New subscription:', {
    serviceId: serviceId.toString(),
    user,
    expiry: new Date(Number(expiry) * 1000)
  });
});

// Listen for withdrawals
microSubs.on('EarningsWithdrawn', (serviceId, creator, amount, event) => {
  console.log('Earnings withdrawn:', {
    serviceId: serviceId.toString(),
    creator,
    amount: ethers.formatEther(amount)
  });
});

// Clean up listeners when done
// microSubs.removeAllListeners();
```

## React Component Example

```jsx
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import MicroSubsABI from './MicroSubs.abi.json';

const CONTRACT_ADDRESS = '0x...';

function SubscriptionManager() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState(null);
  const [services, setServices] = useState([]);

  // Connect wallet
  const connectWallet = async () => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const address = await signer.getAddress();
      
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        MicroSubsABI,
        signer
      );
      
      setProvider(provider);
      setSigner(signer);
      setContract(contract);
      setAccount(address);
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  };

  // Create service
  const createService = async (price) => {
    try {
      const priceInWei = ethers.parseEther(price);
      const tx = await contract.createService(priceInWei);
      await tx.wait();
      alert('Service created successfully!');
      loadServices();
    } catch (error) {
      console.error('Error creating service:', error);
      alert('Error creating service');
    }
  };

  // Subscribe to service
  const subscribe = async (serviceId, price) => {
    try {
      const priceInWei = ethers.parseEther(price);
      const tx = await contract.subscribe(serviceId, { value: priceInWei });
      await tx.wait();
      alert('Subscribed successfully!');
      loadServices();
    } catch (error) {
      console.error('Error subscribing:', error);
      alert('Error subscribing');
    }
  };

  // Check subscription status
  const checkSubscription = async (serviceId) => {
    try {
      const isSubscribed = await contract.isSubscribed(account, serviceId);
      if (isSubscribed) {
        const expiry = await contract.getSubscriptionExpiry(account, serviceId);
        const expiryDate = new Date(Number(expiry) * 1000);
        return { isSubscribed: true, expiry: expiryDate };
      }
      return { isSubscribed: false };
    } catch (error) {
      console.error('Error checking subscription:', error);
      return { isSubscribed: false };
    }
  };

  // Load services
  const loadServices = async () => {
    if (!contract) return;
    
    try {
      const nextServiceId = await contract.getNextServiceId();
      const serviceList = [];
      
      for (let i = 0; i < Number(nextServiceId); i++) {
        const [creator, price, exists] = await contract.getServiceDetails(i);
        if (exists) {
          const subscription = await checkSubscription(i);
          serviceList.push({
            id: i,
            creator,
            price: ethers.formatEther(price),
            subscription
          });
        }
      }
      
      setServices(serviceList);
    } catch (error) {
      console.error('Error loading services:', error);
    }
  };

  useEffect(() => {
    if (contract) {
      loadServices();
    }
  }, [contract]);

  return (
    <div className="subscription-manager">
      <h1>MicroSubs</h1>
      
      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <div>
          <p>Connected: {account}</p>
          
          <div className="create-service">
            <h2>Create Service</h2>
            <input type="number" id="price" placeholder="Price in ETH" step="0.01" />
            <button onClick={() => {
              const price = document.getElementById('price').value;
              createService(price);
            }}>
              Create Service
            </button>
          </div>
          
          <div className="services">
            <h2>Available Services</h2>
            {services.map(service => (
              <div key={service.id} className="service-card">
                <h3>Service #{service.id}</h3>
                <p>Creator: {service.creator}</p>
                <p>Price: {service.price} ETH/month</p>
                
                {service.subscription.isSubscribed ? (
                  <div className="subscribed">
                    <p>✓ Subscribed</p>
                    <p>Expires: {service.subscription.expiry.toLocaleDateString()}</p>
                  </div>
                ) : (
                  <button onClick={() => subscribe(service.id, service.price)}>
                    Subscribe
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default SubscriptionManager;
```

## Error Handling

```javascript
function handleContractError(error) {
  // Parse custom errors
  if (error.data) {
    const errorSelector = error.data.slice(0, 10);
    
    const errors = {
      '0x...': 'Service does not exist',
      '0x...': 'Invalid price',
      '0x...': 'Incorrect payment amount',
      '0x...': 'Not service creator',
      '0x...': 'No earnings to withdraw',
      '0x...': 'Transfer failed'
    };
    
    return errors[errorSelector] || 'Unknown error';
  }
  
  // Handle common errors
  if (error.code === 'ACTION_REJECTED') {
    return 'Transaction rejected by user';
  }
  
  if (error.code === 'INSUFFICIENT_FUNDS') {
    return 'Insufficient funds';
  }
  
  return error.message || 'Unknown error';
}
```

## Best Practices

### 1. Loading States

```javascript
const [loading, setLoading] = useState(false);

async function subscribe(serviceId, price) {
  setLoading(true);
  try {
    const tx = await contract.subscribe(serviceId, { value: price });
    await tx.wait();
  } catch (error) {
    console.error(error);
  } finally {
    setLoading(false);
  }
}
```

### 2. Transaction Confirmation

```javascript
async function subscribeWithConfirmation(serviceId, price) {
  const tx = await contract.subscribe(serviceId, { value: price });
  
  // Show pending state
  console.log('Transaction pending:', tx.hash);
  
  // Wait for 1 confirmation
  const receipt = await tx.wait(1);
  
  // Show success
  console.log('Transaction confirmed:', receipt.transactionHash);
  
  return receipt;
}
```

### 3. Gas Estimation

```javascript
async function estimateSubscriptionGas(serviceId, price) {
  try {
    const gasEstimate = await contract.subscribe.estimateGas(
      serviceId,
      { value: price }
    );
    
    console.log('Estimated gas:', gasEstimate.toString());
    
    // Add 20% buffer
    const gasLimit = gasEstimate * 120n / 100n;
    
    return gasLimit;
  } catch (error) {
    console.error('Gas estimation failed:', error);
    return null;
  }
}
```

### 4. Network Detection

```javascript
async function checkNetwork() {
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  
  const supportedNetworks = {
    1: 'Ethereum Mainnet',
    11155111: 'Sepolia Testnet',
    31337: 'Local Network'
  };
  
  if (!supportedNetworks[chainId]) {
    throw new Error(`Unsupported network: ${chainId}`);
  }
  
  console.log('Connected to:', supportedNetworks[chainId]);
}
```

## Testing Frontend Integration

```javascript
// Mock contract for testing
const mockContract = {
  createService: jest.fn(),
  subscribe: jest.fn(),
  isSubscribed: jest.fn(),
  getServiceDetails: jest.fn(),
  withdrawEarnings: jest.fn()
};

// Test component
test('creates service successfully', async () => {
  mockContract.createService.mockResolvedValue({
    wait: () => Promise.resolve({ logs: [] })
  });
  
  // Test your component
});
```

## Resources

- [ethers.js Documentation](https://docs.ethers.org/)
- [MetaMask Documentation](https://docs.metamask.io/)
- [Web3 React](https://github.com/Uniswap/web3-react)
- [RainbowKit](https://www.rainbowkit.com/)
- [wagmi](https://wagmi.sh/)

## Next Steps

1. Build a complete frontend with React/Next.js
2. Add wallet connection with RainbowKit or wagmi
3. Implement service discovery and search
4. Add user dashboard for managing subscriptions
5. Integrate with IPFS for service metadata
6. Build creator analytics dashboard
7. Add email notifications (off-chain)

Happy building! 🚀
