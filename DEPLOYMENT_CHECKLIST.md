# MicroSubs Deployment Checklist

Complete checklist for deploying MicroSubs to production.

## Pre-Deployment

### 1. Code Review
- [ ] All functions have NatSpec documentation
- [ ] No TODO or FIXME comments remain
- [ ] No console.log statements in production code
- [ ] All magic numbers are replaced with constants
- [ ] Code follows style guide consistently

### 2. Testing
- [ ] All unit tests pass: `forge test`
- [ ] All integration tests pass
- [ ] Fuzz tests run successfully
- [ ] Coverage is 100%: `forge coverage`
- [ ] Gas costs are within acceptable limits: `forge test --gas-report`
- [ ] No failing tests on CI/CD

### 3. Security Review
- [ ] No reentrancy vulnerabilities
- [ ] Access control properly implemented
- [ ] Integer overflow/underflow handled (Solidity 0.8+)
- [ ] External calls follow CEI pattern
- [ ] No delegatecall or selfdestruct
- [ ] Custom errors used for gas efficiency
- [ ] Events emitted for all state changes
- [ ] Consider professional audit for mainnet

### 4. Documentation
- [ ] README.md is complete and accurate
- [ ] All public functions documented
- [ ] Deployment guide is clear
- [ ] Frontend integration guide available
- [ ] Architecture diagrams up to date

## Testnet Deployment

### 1. Environment Setup
```bash
# Create .env file
cp .env.example .env

# Add your credentials
# - SEPOLIA_RPC_URL
# - PRIVATE_KEY (testnet only!)
# - ETHERSCAN_API_KEY
```

- [ ] RPC URL configured
- [ ] Private key secured (testnet wallet only)
- [ ] Etherscan API key obtained
- [ ] Test wallet funded with Sepolia ETH

### 2. Deploy to Sepolia
```bash
# Deploy
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify

# Or manual deployment
forge create src/MicroSubs.sol:MicroSubs \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

- [ ] Contract deployed successfully
- [ ] Contract verified on Etherscan
- [ ] Deployment transaction confirmed
- [ ] Contract address saved

### 3. Post-Deployment Testing
```bash
# Set contract address
export MICROSUBS_ADDRESS=0x...

# Test interactions
cast call $MICROSUBS_ADDRESS "getNextServiceId()" --rpc-url $SEPOLIA_RPC_URL
```

- [ ] Create test service
- [ ] Subscribe to test service
- [ ] Verify subscription status
- [ ] Test withdrawal
- [ ] Check events on Etherscan
- [ ] Verify gas costs match estimates

### 4. Integration Testing
- [ ] Frontend connects successfully
- [ ] MetaMask integration works
- [ ] All user flows functional
- [ ] Events properly indexed
- [ ] Error handling works correctly

## Mainnet Deployment

### 1. Final Security Checks
- [ ] Code frozen (no more changes)
- [ ] Professional audit completed (recommended)
- [ ] Audit findings addressed
- [ ] Testnet deployment stable for 1+ week
- [ ] No critical issues found
- [ ] Team review completed

### 2. Mainnet Preparation
- [ ] Mainnet RPC URL configured
- [ ] Hardware wallet or secure key management
- [ ] Sufficient ETH for deployment (~0.05 ETH)
- [ ] Deployment script tested on fork
- [ ] Emergency response plan ready
- [ ] Team available for monitoring

### 3. Deploy to Mainnet
```bash
# IMPORTANT: Use hardware wallet or secure key management!
# Test on fork first:
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $MAINNET_RPC_URL \
  --fork-url $MAINNET_RPC_URL

# Then deploy for real:
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --slow  # Use --slow to avoid rate limits
```

- [ ] Contract deployed to mainnet
- [ ] Contract verified on Etherscan
- [ ] Deployment transaction confirmed (multiple blocks)
- [ ] Contract address documented
- [ ] Deployment announcement prepared

### 4. Post-Mainnet Deployment
- [ ] Verify contract on Etherscan
- [ ] Test basic functionality with small amounts
- [ ] Monitor for first 24 hours
- [ ] Update frontend with mainnet address
- [ ] Announce deployment to community
- [ ] Add contract to monitoring tools

## Monitoring & Maintenance

### 1. Set Up Monitoring
- [ ] Etherscan alerts configured
- [ ] Transaction monitoring active
- [ ] Gas price alerts set
- [ ] Error tracking enabled
- [ ] Analytics dashboard created

### 2. Documentation Updates
- [ ] Contract address in README
- [ ] Etherscan link added
- [ ] Frontend updated with mainnet address
- [ ] Deployment date documented
- [ ] Version tagged in git

### 3. Community Communication
- [ ] Deployment announcement posted
- [ ] Documentation shared
- [ ] Support channels ready
- [ ] FAQ prepared
- [ ] Tutorial videos created (optional)

## Emergency Procedures

### If Issues Detected
1. **Stop promoting the contract immediately**
2. **Assess the severity**
3. **Communicate with users**
4. **Deploy fix if possible (new contract)**
5. **Document incident**

### Contact Information
- [ ] Team contact list prepared
- [ ] Security researcher contacts ready
- [ ] Community communication channels set

## Deployment Record

### Testnet Deployments
```
Network: Sepolia
Address: 0x...
Deployer: 0x...
Block: #...
Date: YYYY-MM-DD
Etherscan: https://sepolia.etherscan.io/address/0x...
```

### Mainnet Deployment
```
Network: Ethereum Mainnet
Address: 0x...
Deployer: 0x...
Block: #...
Date: YYYY-MM-DD
Etherscan: https://etherscan.io/address/0x...
Gas Used: ...
Deployment Cost: ... ETH
```

## Post-Launch Checklist

### Week 1
- [ ] Monitor all transactions
- [ ] Check for unexpected behavior
- [ ] Respond to user questions
- [ ] Fix documentation issues
- [ ] Gather user feedback

### Month 1
- [ ] Analyze usage patterns
- [ ] Review gas costs
- [ ] Check for optimization opportunities
- [ ] Plan improvements
- [ ] Consider V2 features

### Ongoing
- [ ] Regular security reviews
- [ ] Keep dependencies updated
- [ ] Monitor Solidity updates
- [ ] Engage with community
- [ ] Plan future enhancements

## Resources

### Deployment Tools
- [Foundry Deployment](https://book.getfoundry.sh/reference/forge/forge-create)
- [Etherscan Verification](https://docs.etherscan.io/tutorials/verifying-contracts-programmatically)
- [Tenderly Monitoring](https://tenderly.co/)

### Security Resources
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [Audit Firms List](https://github.com/ConsenSys/smart-contract-best-practices#security-tools)
- [Bug Bounty Platforms](https://immunefi.com/)

### Monitoring Tools
- [Etherscan](https://etherscan.io/)
- [Tenderly](https://tenderly.co/)
- [Dune Analytics](https://dune.com/)
- [The Graph](https://thegraph.com/)

---

**Remember: Deploying to mainnet is irreversible. Take your time and double-check everything!**

## Sign-Off

Deployment approved by:
- [ ] Lead Developer: _________________ Date: _______
- [ ] Security Reviewer: ______________ Date: _______
- [ ] Project Manager: ________________ Date: _______

Deployment completed by: _________________ Date: _______
