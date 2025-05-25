# DeFiAid Smart Contracts

This directory contains the smart contracts for the DeFiAid platform, a decentralized crowdfunding platform where users can create fundraising campaigns and receive donations through blockchain technology.

## Contract Architecture

### AdminRegistry.sol
Manages admin roles and permissions for the platform. Admins have special privileges to moderate campaigns and manage the platform.

### CampaignFactory.sol
Factory contract that deploys individual campaign contracts. It maintains a registry of all campaigns and controls platform settings like fees.

### Campaign.sol
Individual campaign contract that handles donations, withdrawals, and campaign lifecycle management.

## Setup

### Prerequisites
- Node.js (v14+)
- npm or yarn

### Installation

```bash
npm install
```

## Configuration

Create a `.env` file in the root of the contracts directory with the following variables:

```
# Network RPC URLs
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.io/v2/your-api-key
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.io/v2/your-api-key

# Private key for deployment (without 0x prefix)
PRIVATE_KEY=your-private-key-here

# Etherscan API Key for contract verification
ETHERSCAN_API_KEY=your-etherscan-api-key

# Contract parameters
PLATFORM_WALLET_ADDRESS=0xYourPlatformWalletAddress
USDT_ADDRESS_SEPOLIA=0xUSDTAddressOnSepolia
USDT_ADDRESS_MAINNET=0xdAC17F958D2ee523a2206206994597C13D831ec7

# Admin addresses for AdminRegistry (comma-separated)
ADMIN_ADDRESSES=0xAdmin1Address,0xAdmin2Address
```

## Compilation

```bash
npm run compile
```

## Deployment

### Local Development

```bash
npm run node
```

In a separate terminal:

```bash
npm run deploy
```

### Sepolia Testnet

```bash
npm run deploy:sepolia
```

### Ethereum Mainnet

```bash
npm run deploy:mainnet
```

## Contract Verification

If the automatic verification during deployment fails, you can verify the contracts separately:

### Sepolia Testnet

```bash
npm run verify:sepolia
```

### Ethereum Mainnet

```bash
npm run verify:mainnet
```

## Deployment Output

After successful deployment, the script will:

1. Output the addresses of the deployed contracts in the console
2. Save the deployment information to a JSON file in the `deployments` directory
3. Update the frontend environment variables in `../frontend/.env.local`

## KYC Verification

The CampaignFactory contract includes KYC verification functionality. Only KYC-verified creators can create campaigns. Admins can set the KYC status of creators using the `setCreatorKYCStatus` or `batchSetCreatorKYCStatus` functions.

## Admin Management

The AdminRegistry contract manages admin roles. The contract owner can add or remove admins using the `addAdmin` and `removeAdmin` functions.

## Platform Fee

The platform charges a 2.9% fee on all withdrawals from campaigns. This fee can be adjusted by admins using the `updatePlatformFee` function in the CampaignFactory contract.
