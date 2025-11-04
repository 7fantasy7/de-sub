# MicroSubs Frontend

Minimal React frontend for interacting with MicroSubs smart contract on Sepolia testnet.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ installed
- MetaMask browser extension
- Sepolia testnet ETH (get from [Sepolia Faucet](https://sepoliafaucet.com/))

### Installation

```bash
cd frontend
npm install
```

### Configuration

1. Deploy the MicroSubs contract to Sepolia testnet:
```bash
cd ..
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

2. Update `src/config.js` with your deployed contract address:
```javascript
export const CONTRACT_ADDRESS = "0xYourContractAddress";
```

### Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## 📱 Features

### Browse Services
- View all available services
- See service details (price, subscribers, status)
- Subscribe to services
- Renew existing subscriptions
- Check subscription expiry

### Create Service
- Create new subscription services
- Set monthly price in ETH
- Instant deployment

### Manage Services
- View your created services
- Withdraw accumulated earnings
- Pause/unpause services
- Update service prices
- Monitor subscriber counts

## 🎨 UI Features

- **Wallet Connection**: MetaMask integration
- **Network Detection**: Auto-switch to Sepolia
- **Real-time Updates**: Refresh button to sync state
- **Responsive Design**: Works on mobile and desktop
- **Status Indicators**: Visual feedback for all actions
- **Error Handling**: Clear error messages

## 🔧 Tech Stack

- **React 18** - UI framework
- **Vite** - Build tool
- **ethers.js v6** - Ethereum interaction
- **MetaMask** - Wallet provider

## 📝 Usage Guide

### For Users (Subscribers)

1. **Connect Wallet**
   - Click "Connect Wallet"
   - Approve MetaMask connection
   - Ensure you're on Sepolia testnet

2. **Browse Services**
   - View available services in the Browse tab
   - Check prices and subscriber counts
   - See if service is active or paused

3. **Subscribe**
   - Click "Subscribe" on desired service
   - Approve transaction in MetaMask
   - Wait for confirmation

4. **Check Subscription**
   - Green badge shows active subscription
   - Expiry date displayed
   - Click "Renew" to extend

### For Creators

1. **Create Service**
   - Go to "Create Service" tab
   - Enter monthly price in ETH
   - Click "Create Service"
   - Approve transaction

2. **Manage Services**
   - Go to "Manage" tab
   - View all your services
   - See earnings and subscriber counts

3. **Withdraw Earnings**
   - Click "Withdraw" on service card
   - Approve transaction
   - ETH sent to your wallet

4. **Pause/Unpause**
   - Click "Pause" to stop new subscriptions
   - Existing subscribers keep access
   - Click "Unpause" to resume

5. **Update Price**
   - Use "Update Service Price" form
   - Enter service ID and new price
   - Existing subscribers keep old price
   - New subscribers pay new price

## 🔐 Security Notes

- Never share your private keys
- Always verify contract address
- Check transaction details before signing
- Use testnet ETH for testing
- This is a demo - audit before mainnet use

## 🐛 Troubleshooting

### "Please install MetaMask"
- Install MetaMask browser extension
- Refresh the page

### "Please switch to Sepolia testnet"
- Open MetaMask
- Click network dropdown
- Select "Sepolia test network"
- Or click the prompt to auto-switch

### "Failed to load services"
- Check contract address in `config.js`
- Ensure contract is deployed
- Check MetaMask connection
- Try refreshing the page

### Transaction Fails
- Ensure sufficient ETH balance
- Check gas price
- Verify you're on correct network
- Try increasing gas limit

## 📦 Build for Production

```bash
npm run build
```

Output in `dist/` folder. Deploy to any static hosting:
- Vercel
- Netlify
- GitHub Pages
- IPFS

## 🔗 Useful Links

- [Sepolia Faucet](https://sepoliafaucet.com/)
- [Sepolia Explorer](https://sepolia.etherscan.io/)
- [MetaMask](https://metamask.io/)
- [ethers.js Docs](https://docs.ethers.org/v6/)

## 📄 License

MIT
