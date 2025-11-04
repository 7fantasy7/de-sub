import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { CONTRACT_ADDRESS, CONTRACT_ABI, SEPOLIA_CHAIN_ID } from './config'

function App() {
  const [account, setAccount] = useState(null)
  const [provider, setProvider] = useState(null)
  const [contract, setContract] = useState(null)
  const [activeTab, setActiveTab] = useState('browse')
  const [services, setServices] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  // Form states
  const [newServicePrice, setNewServicePrice] = useState('')
  const [updateServiceId, setUpdateServiceId] = useState('')
  const [updatePrice, setUpdatePrice] = useState('')

  useEffect(() => {
    checkWalletConnection()
  }, [])

  useEffect(() => {
    if (contract) {
      loadServices()
    }
  }, [contract])

  const checkWalletConnection = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_accounts' })
        if (accounts.length > 0) {
          await connectWallet()
        }
      } catch (err) {
        console.error('Error checking wallet:', err)
      }
    }
  }

  const connectWallet = async () => {
    if (typeof window.ethereum === 'undefined') {
      setError('Please install MetaMask to use this app')
      return
    }

    try {
      setLoading(true)
      setError('')

      // Request account access
      const accounts = await window.ethereum.request({ 
        method: 'eth_requestAccounts' 
      })

      // Check network
      const chainId = await window.ethereum.request({ method: 'eth_chainId' })
      if (chainId !== SEPOLIA_CHAIN_ID) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: SEPOLIA_CHAIN_ID }],
          })
        } catch (switchError) {
          setError('Please switch to Sepolia testnet in MetaMask')
          setLoading(false)
          return
        }
      }

      // Setup provider and contract
      const provider = new ethers.BrowserProvider(window.ethereum)
      const signer = await provider.getSigner()
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer)

      setAccount(accounts[0])
      setProvider(provider)
      setContract(contract)
      setSuccess('Wallet connected successfully!')
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const loadServices = async () => {
    try {
      setLoading(true)
      const nextId = await contract.getNextServiceId()
      const servicesData = []

      for (let i = 0; i < nextId; i++) {
        const [creator, price, exists, paused, subscriberCount] = await contract.getServiceInfo(i)
        if (exists) {
          const earnings = await contract.getEarnings(i)
          const isSubscribed = account ? await contract.isSubscribed(account, i) : false
          let expiry = null
          if (isSubscribed && account) {
            expiry = await contract.getSubscriptionExpiry(account, i)
          }

          servicesData.push({
            id: i,
            creator,
            price: ethers.formatEther(price),
            paused,
            subscriberCount: subscriberCount.toString(),
            earnings: ethers.formatEther(earnings),
            isSubscribed,
            expiry: expiry ? new Date(Number(expiry) * 1000) : null
          })
        }
      }

      setServices(servicesData)
    } catch (err) {
      console.error('Error loading services:', err)
      setError('Failed to load services')
    } finally {
      setLoading(false)
    }
  }

  const createService = async (e) => {
    e.preventDefault()
    if (!newServicePrice) return

    try {
      setLoading(true)
      setError('')
      
      const priceWei = ethers.parseEther(newServicePrice)
      const tx = await contract.createService(priceWei)
      await tx.wait()
      
      setSuccess('Service created successfully!')
      setNewServicePrice('')
      await loadServices()
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const subscribe = async (serviceId, price) => {
    try {
      setLoading(true)
      setError('')
      
      const priceWei = ethers.parseEther(price)
      const tx = await contract.subscribe(serviceId, { value: priceWei })
      await tx.wait()
      
      setSuccess('Subscribed successfully!')
      await loadServices()
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const withdrawEarnings = async (serviceId) => {
    try {
      setLoading(true)
      setError('')
      
      const tx = await contract.withdrawEarnings(serviceId)
      await tx.wait()
      
      setSuccess('Earnings withdrawn successfully!')
      await loadServices()
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const updateServicePrice = async (e) => {
    e.preventDefault()
    if (!updateServiceId || !updatePrice) return

    try {
      setLoading(true)
      setError('')
      
      const priceWei = ethers.parseEther(updatePrice)
      const tx = await contract.updateServicePrice(updateServiceId, priceWei)
      await tx.wait()
      
      setSuccess('Price updated successfully!')
      setUpdateServiceId('')
      setUpdatePrice('')
      await loadServices()
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const togglePause = async (serviceId, isPaused) => {
    try {
      setLoading(true)
      setError('')
      
      const tx = isPaused 
        ? await contract.unpauseService(serviceId)
        : await contract.pauseService(serviceId)
      await tx.wait()
      
      setSuccess(`Service ${isPaused ? 'unpaused' : 'paused'} successfully!`)
      await loadServices()
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const isCreator = (service) => {
    return account && service.creator.toLowerCase() === account.toLowerCase()
  }

  return (
    <div className="app">
      <div className="header">
        <h1>🔔 MicroSubs</h1>
        <p>Decentralized Subscription Management</p>
      </div>

      {!account ? (
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <button onClick={connectWallet} className="btn btn-primary" disabled={loading}>
            {loading ? 'Connecting...' : 'Connect Wallet'}
          </button>
          {error && <div className="error" style={{ marginTop: '20px' }}>{error}</div>}
        </div>
      ) : (
        <>
          <div className="wallet-section">
            <div className="wallet-info">
              <span className="network-badge">Sepolia Testnet</span>
              <span className="wallet-address">
                {account.slice(0, 6)}...{account.slice(-4)}
              </span>
            </div>
            <button onClick={loadServices} className="btn btn-secondary" disabled={loading}>
              {loading ? 'Loading...' : '🔄 Refresh'}
            </button>
          </div>

          {error && <div className="error">{error}</div>}
          {success && <div className="success">{success}</div>}

          <div className="tabs">
            <button 
              className={`tab ${activeTab === 'browse' ? 'active' : ''}`}
              onClick={() => setActiveTab('browse')}
            >
              Browse Services
            </button>
            <button 
              className={`tab ${activeTab === 'create' ? 'active' : ''}`}
              onClick={() => setActiveTab('create')}
            >
              Create Service
            </button>
            <button 
              className={`tab ${activeTab === 'manage' ? 'active' : ''}`}
              onClick={() => setActiveTab('manage')}
            >
              Manage
            </button>
          </div>

          {activeTab === 'browse' && (
            <div>
              {loading ? (
                <div className="loading">Loading services...</div>
              ) : services.length === 0 ? (
                <div className="empty-state">
                  <h3>No services yet</h3>
                  <p>Be the first to create a service!</p>
                </div>
              ) : (
                <div className="services-grid">
                  {services.map(service => (
                    <div key={service.id} className="service-card">
                      <div className="service-header">
                        <span className="service-id">Service #{service.id}</span>
                        <span className={`service-status ${service.paused ? 'status-paused' : 'status-active'}`}>
                          {service.paused ? 'PAUSED' : 'ACTIVE'}
                        </span>
                      </div>

                      <div className="service-price">{service.price} ETH/month</div>

                      <div className="service-info">
                        <p><strong>Creator:</strong> {service.creator.slice(0, 6)}...{service.creator.slice(-4)}</p>
                        <p><strong>Subscribers:</strong> {service.subscriberCount}</p>
                      </div>

                      {service.isSubscribed && service.expiry && (
                        <div className="subscription-info">
                          <p><strong>✓ Subscribed</strong></p>
                          <p>Expires: {service.expiry.toLocaleDateString()}</p>
                        </div>
                      )}

                      <div className="service-actions">
                        {!service.paused && (
                          <button 
                            onClick={() => subscribe(service.id, service.price)}
                            className="btn btn-primary"
                            disabled={loading}
                          >
                            {service.isSubscribed ? 'Renew' : 'Subscribe'}
                          </button>
                        )}
                        {service.paused && (
                          <button className="btn btn-secondary" disabled>
                            Service Paused
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {activeTab === 'create' && (
            <div className="section">
              <h2>Create New Service</h2>
              <form onSubmit={createService}>
                <div className="form-group">
                  <label>Monthly Price (ETH)</label>
                  <input
                    type="number"
                    step="0.001"
                    placeholder="0.1"
                    value={newServicePrice}
                    onChange={(e) => setNewServicePrice(e.target.value)}
                    required
                  />
                </div>
                <button type="submit" className="btn btn-primary" disabled={loading}>
                  {loading ? 'Creating...' : 'Create Service'}
                </button>
              </form>
            </div>
          )}

          {activeTab === 'manage' && (
            <div>
              <div className="section">
                <h2>Your Services</h2>
                {services.filter(s => isCreator(s)).length === 0 ? (
                  <p style={{ color: '#999' }}>You haven't created any services yet.</p>
                ) : (
                  <div className="services-grid">
                    {services.filter(s => isCreator(s)).map(service => (
                      <div key={service.id} className="service-card">
                        <div className="service-header">
                          <span className="service-id">Service #{service.id}</span>
                          <span className={`service-status ${service.paused ? 'status-paused' : 'status-active'}`}>
                            {service.paused ? 'PAUSED' : 'ACTIVE'}
                          </span>
                        </div>

                        <div className="service-price">{service.price} ETH/month</div>

                        <div className="service-info">
                          <p><strong>Subscribers:</strong> {service.subscriberCount}</p>
                          <p><strong>Earnings:</strong> {service.earnings} ETH</p>
                        </div>

                        <div className="service-actions">
                          {parseFloat(service.earnings) > 0 && (
                            <button 
                              onClick={() => withdrawEarnings(service.id)}
                              className="btn btn-success"
                              disabled={loading}
                            >
                              Withdraw
                            </button>
                          )}
                          <button 
                            onClick={() => togglePause(service.id, service.paused)}
                            className={`btn ${service.paused ? 'btn-success' : 'btn-danger'}`}
                            disabled={loading}
                          >
                            {service.paused ? 'Unpause' : 'Pause'}
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div className="section">
                <h2>Update Service Price</h2>
                <form onSubmit={updateServicePrice}>
                  <div className="form-group">
                    <label>Service ID</label>
                    <input
                      type="number"
                      placeholder="0"
                      value={updateServiceId}
                      onChange={(e) => setUpdateServiceId(e.target.value)}
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label>New Price (ETH)</label>
                    <input
                      type="number"
                      step="0.001"
                      placeholder="0.2"
                      value={updatePrice}
                      onChange={(e) => setUpdatePrice(e.target.value)}
                      required
                    />
                  </div>
                  <button type="submit" className="btn btn-primary" disabled={loading}>
                    {loading ? 'Updating...' : 'Update Price'}
                  </button>
                </form>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}

export default App
