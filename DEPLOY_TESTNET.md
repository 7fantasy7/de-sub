# Deploy to Sepolia Testnet - Complete Guide

Step-by-step guide to deploy MicroSubs contract and frontend to Sepolia testnet.

## 📋 Prerequisites

- [ ] Foundry installed (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- [ ] Node.js 18+ installed
- [ ] MetaMask wallet with Sepolia ETH
- [ ] Etherscan API key (for verification)

## 🔑 Step 1: Get Testnet ETH

1. Get Sepolia ETH from faucets:
   - [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
   - [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)
   - [QuickNode Faucet](https://faucet.quicknode.com/ethereum/sepolia)

2. You'll need ~0.1 ETH for deployment and testing

## 🔧 Step 2: Setup Environment

1. Copy environment template:
```bash
cp .env.example .env
```

2. Edit `.env` file:
```bash
# Get RPC URL from:
# - Alchemy: https://www.alchemy.com/
# - Infura: https://www.infura.io/
# - QuickNode: https://www.quicknode.com/
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Your wallet private key (NEVER commit this!)
PRIVATE_KEY=your_private_key_here

# Get from https://etherscan.io/myapikey
ETHERSCAN_API_KEY=your_etherscan_api_key
```

3. **Security Warning**: Never commit `.env` file to git!

## 🚀 Step 3: Deploy Contract

1. Build the contract:
```bash
forge build
```

2. Run tests to verify:
```bash
forge test
```

3. Deploy to Sepolia:
```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

4. Save the deployed contract address from output:
```
Contract deployed at: 0x1234567890123456789012345678901234567890
```

## ✅ Step 4: Verify Deployment

1. Check on Etherscan:
   - Go to https://sepolia.etherscan.io/
   - Search for your contract address
   - Verify contract is deployed and verified

2. Test contract interaction:
```bash
# Create a test service
cast send $CONTRACT_ADDRESS \
  "createService(uint256)" 100000000000000000 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Check next service ID
cast call $CONTRACT_ADDRESS \
  "getNextServiceId()" \
  --rpc-url $SEPOLIA_RPC_URL
```

## 🎨 Step 5: Setup Frontend

1. Navigate to frontend:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Update contract address in `src/config.js`:
```javascript
export const CONTRACT_ADDRESS = "0x1234..."; // Your deployed address
```

4. Start development server:
```bash
npm run dev
```

5. Open http://localhost:3000

## 🧪 Step 6: Test Frontend

1. **Connect Wallet**
   - Click "Connect Wallet"
   - Approve MetaMask
   - Ensure Sepolia network

2. **Create Test Service**
   - Go to "Create Service" tab
   - Enter price: 0.01 ETH
   - Click "Create Service"
   - Approve transaction

3. **Subscribe to Service**
   - Go to "Browse Services" tab
   - Click "Subscribe" on your service
   - Approve transaction with 0.01 ETH

4. **Test Management**
   - Go to "Manage" tab
   - View your service
   - Try withdrawing earnings
   - Test pause/unpause

## 🌐 Step 7: Deploy Frontend (Optional)

### Option A: Vercel

1. Install Vercel CLI:
```bash
npm i -g vercel
```

2. Deploy:
```bash
cd frontend
vercel
```

3. Follow prompts, your site will be live!

### Option B: Netlify

1. Build frontend:
```bash
npm run build
```

2. Deploy `dist/` folder to Netlify:
   - Go to https://app.netlify.com/
   - Drag and drop `dist/` folder
   - Site is live!

### Option C: GitHub Pages

1. Update `vite.config.js`:
```javascript
export default defineConfig({
  base: '/your-repo-name/',
  // ... rest of config
})
```

2. Build and deploy:
```bash
npm run build
git add dist -f
git commit -m "Deploy"
git subtree push --prefix frontend/dist origin gh-pages
```

## 📊 Step 8: Monitor & Maintain

### Check Contract Activity

```bash
# View recent transactions
cast logs --address $CONTRACT_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL

# Check service count
cast call $CONTRACT_ADDRESS \
  "getNextServiceId()" \
  --rpc-url $SEPOLIA_RPC_URL

# Get service info
cast call $CONTRACT_ADDRESS \
  "getServiceInfo(uint256)" 0 \
  --rpc-url $SEPOLIA_RPC_URL
```

### Monitor on Etherscan

- View transactions: https://sepolia.etherscan.io/address/YOUR_ADDRESS
- Check events and logs
- Monitor gas usage

## 🐛 Troubleshooting

### Deployment Fails

**"Insufficient funds"**
- Get more Sepolia ETH from faucets
- Check balance: `cast balance $YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL`

**"Nonce too low"**
- Reset MetaMask account
- Or specify nonce: `--nonce X`

**"Verification failed"**
- Wait a few minutes and try again
- Check Etherscan API key is correct
- Manually verify on Etherscan

### Frontend Issues

**"Please switch to Sepolia"**
- Open MetaMask
- Switch to Sepolia network
- Refresh page

**"Failed to load services"**
- Check contract address in config.js
- Verify contract is deployed
- Check browser console for errors

**Transaction Fails**
- Ensure sufficient ETH
- Check gas price
- Try increasing gas limit in MetaMask

## 📝 Deployment Checklist

- [ ] Contract compiled successfully
- [ ] All tests passing
- [ ] Environment variables set
- [ ] Sepolia ETH in wallet
- [ ] Contract deployed to Sepolia
- [ ] Contract verified on Etherscan
- [ ] Contract address saved
- [ ] Frontend config updated
- [ ] Frontend tested locally
- [ ] Test service created
- [ ] Test subscription works
- [ ] Withdrawal tested
- [ ] Frontend deployed (optional)

## 🎉 Success!

Your MicroSubs contract is now live on Sepolia testnet!

**Next Steps:**
- Share your frontend URL with testers
- Create real services
- Gather feedback
- Consider mainnet deployment (after audit!)

## 🔗 Useful Resources

- [Sepolia Faucet](https://sepoliafaucet.com/)
- [Sepolia Explorer](https://sepolia.etherscan.io/)
- [Alchemy Dashboard](https://dashboard.alchemy.com/)
- [Foundry Book](https://book.getfoundry.sh/)
- [ethers.js Docs](https://docs.ethers.org/v6/)

## ⚠️ Important Notes

1. **Never use testnet private keys on mainnet**
2. **Always verify contract source code**
3. **Test thoroughly before mainnet**
4. **Consider professional audit for mainnet**
5. **Keep private keys secure**

---

**Need Help?**
- Check Foundry docs
- Review test cases
- Check browser console
- Verify network and addresses
