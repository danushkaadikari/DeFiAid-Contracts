// Deployment script for DeFiAid contracts
const hre = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("Starting deployment process...");
  
  // Get network information
  const network = hre.network.name;
  console.log(`Deploying to ${network} network`);
  
  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);
  
  // Get balance of deployer
  const deployerBalance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`Account balance: ${hre.ethers.formatEther(deployerBalance)} ETH`);
  
  // Get contract parameters from environment variables
  let platformWalletAddress = process.env.PLATFORM_WALLET_ADDRESS;
  let usdtAddress;
  
  if (network === "sepolia") {
    usdtAddress = process.env.USDT_ADDRESS_SEPOLIA;
  } else if (network === "mainnet") {
    usdtAddress = process.env.USDT_ADDRESS_MAINNET;
  } else {
    throw new Error(`Unsupported network: ${network}`);
  }
  
  console.log(`Platform Wallet Address: ${platformWalletAddress}`);
  console.log(`USDT Address: ${usdtAddress}`);
  
  // Parse admin addresses from environment variable
  const adminAddresses = process.env.ADMIN_ADDRESSES.split(',');
  console.log(`Initial Admin Addresses: ${adminAddresses.join(', ')}`);
  
  // Deploy CampaignFactory contract
  console.log("Deploying CampaignFactory contract...");
  const CampaignFactory = await hre.ethers.getContractFactory("CampaignFactory");
  const campaignFactory = await CampaignFactory.deploy(
    platformWalletAddress,
    usdtAddress,
    adminAddresses
  );
  
  await campaignFactory.waitForDeployment();
  const campaignFactoryAddress = await campaignFactory.getAddress();
  console.log(`CampaignFactory deployed to: ${campaignFactoryAddress}`);
  
  // Get the AdminRegistry address from the CampaignFactory
  const adminRegistryAddress = await campaignFactory.adminRegistry();
  console.log(`AdminRegistry deployed to: ${adminRegistryAddress}`);
  
  // Verify contracts on Etherscan if not on a local network
  if (network !== "hardhat" && network !== "localhost") {
    console.log("Waiting for block confirmations before verification...");
    // Wait for 5 block confirmations for better Etherscan verification
    await campaignFactory.deploymentTransaction().wait(5);
    
    console.log("Verifying CampaignFactory contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: campaignFactoryAddress,
        constructorArguments: [
          platformWalletAddress,
          usdtAddress,
          adminAddresses
        ],
      });
      console.log("CampaignFactory verified on Etherscan");
    } catch (error) {
      console.error("Error verifying CampaignFactory:", error);
    }
    
    console.log("Verifying AdminRegistry contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: adminRegistryAddress,
        constructorArguments: [adminAddresses],
      });
      console.log("AdminRegistry verified on Etherscan");
    } catch (error) {
      console.error("Error verifying AdminRegistry:", error);
    }
  }
  
  // Output deployment information
  console.log("\nDeployment Summary:");
  console.log("====================");
  console.log(`Network: ${network}`);
  console.log(`CampaignFactory: ${campaignFactoryAddress}`);
  console.log(`AdminRegistry: ${adminRegistryAddress}`);
  console.log(`Platform Wallet: ${platformWalletAddress}`);
  console.log(`USDT Address: ${usdtAddress}`);
  console.log(`Initial Admins: ${adminAddresses.join(', ')}`);
  
  // Save deployment addresses to a file
  const fs = require("fs");
  const deploymentInfo = {
    network,
    campaignFactory: campaignFactoryAddress,
    adminRegistry: adminRegistryAddress,
    platformWallet: platformWalletAddress,
    usdtAddress,
    timestamp: new Date().toISOString(),
  };
  
  const deploymentPath = `./deployments/${network}.json`;
  
  // Create deployments directory if it doesn't exist
  if (!fs.existsSync('./deployments')) {
    fs.mkdirSync('./deployments', { recursive: true });
  }
  
  fs.writeFileSync(
    deploymentPath,
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log(`Deployment information saved to ${deploymentPath}`);
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
