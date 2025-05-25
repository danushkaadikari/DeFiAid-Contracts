// Improved deployment script for DeFiAid contracts on Sepolia testnet
const hre = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("Starting improved Sepolia testnet deployment...");
  
  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);
  
  // Get balance of deployer
  const deployerBalance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`Account balance: ${hre.ethers.formatEther(deployerBalance)} ETH`);
  
  // Get contract parameters from environment variables
  const platformWalletAddress = process.env.PLATFORM_WALLET_ADDRESS;
  const usdtAddress = process.env.USDT_ADDRESS_SEPOLIA;
  
  if (!platformWalletAddress || platformWalletAddress === "0x0000000000000000000000000000000000000000") {
    throw new Error("Please set a valid PLATFORM_WALLET_ADDRESS in your .env file");
  }
  
  if (!usdtAddress || usdtAddress === "0x0000000000000000000000000000000000000000") {
    throw new Error("Please set a valid USDT_ADDRESS_SEPOLIA in your .env file");
  }
  
  console.log(`Platform Wallet Address: ${platformWalletAddress}`);
  console.log(`USDT Address: ${usdtAddress}`);
  
  // Parse admin addresses from environment variable
  const adminAddresses = process.env.ADMIN_ADDRESSES.split(',');
  console.log(`Initial Admin Addresses: ${adminAddresses.join(', ')}`);
  
  // Step 1: Deploy AdminRegistry contract first
  console.log("Deploying AdminRegistry contract...");
  const AdminRegistry = await hre.ethers.getContractFactory("AdminRegistry");
  const adminRegistry = await AdminRegistry.deploy(adminAddresses);
  
  await adminRegistry.waitForDeployment();
  const adminRegistryAddress = await adminRegistry.getAddress();
  console.log(`AdminRegistry deployed to: ${adminRegistryAddress}`);
  
  // Step 2: Deploy CampaignFactory contract with the AdminRegistry address
  console.log("Deploying CampaignFactory contract...");
  const CampaignFactory = await hre.ethers.getContractFactory("CampaignFactory");
  const campaignFactory = await CampaignFactory.deploy(
    platformWalletAddress,
    usdtAddress,
    adminRegistryAddress
  );
  
  await campaignFactory.waitForDeployment();
  const campaignFactoryAddress = await campaignFactory.getAddress();
  console.log(`CampaignFactory deployed to: ${campaignFactoryAddress}`);
  
  // Verify contracts on Etherscan
  console.log("Waiting for block confirmations before verification...");
  // Wait for 5 block confirmations for better Etherscan verification
  await adminRegistry.deploymentTransaction().wait(5);
  
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
  
  console.log("Verifying CampaignFactory contract on Etherscan...");
  try {
    await hre.run("verify:verify", {
      address: campaignFactoryAddress,
      constructorArguments: [
        platformWalletAddress,
        usdtAddress,
        adminRegistryAddress
      ],
    });
    console.log("CampaignFactory verified on Etherscan");
  } catch (error) {
    console.error("Error verifying CampaignFactory:", error);
  }
  
  // Output deployment information
  console.log("\nDeployment Summary:");
  console.log("====================");
  console.log(`Network: Sepolia Testnet`);
  console.log(`AdminRegistry: ${adminRegistryAddress}`);
  console.log(`CampaignFactory: ${campaignFactoryAddress}`);
  console.log(`Platform Wallet: ${platformWalletAddress}`);
  console.log(`USDT Address: ${usdtAddress}`);
  console.log(`Initial Admins: ${adminAddresses.join(', ')}`);
  
  // Save deployment addresses to a file
  const fs = require("fs");
  const deploymentInfo = {
    network: "sepolia",
    adminRegistry: adminRegistryAddress,
    campaignFactory: campaignFactoryAddress,
    platformWallet: platformWalletAddress,
    usdtAddress,
    timestamp: new Date().toISOString(),
  };
  
  const deploymentPath = `./deployments/sepolia-improved.json`;
  
  // Create deployments directory if it doesn't exist
  if (!fs.existsSync('./deployments')) {
    fs.mkdirSync('./deployments', { recursive: true });
  }
  
  fs.writeFileSync(
    deploymentPath,
    JSON.stringify(deploymentInfo, null, 2)
  );
  
  console.log(`Deployment information saved to ${deploymentPath}`);
  
  // Update the frontend environment variables
  console.log("\nUpdating frontend environment variables...");
  
  const frontendEnvPath = '../frontend/.env.local';
  let frontendEnvContent = '';
  
  try {
    if (fs.existsSync(frontendEnvPath)) {
      frontendEnvContent = fs.readFileSync(frontendEnvPath, 'utf8');
    }
    
    // Add or update the contract addresses in the frontend .env.local file
    const envVars = {
      NEXT_PUBLIC_ADMIN_REGISTRY_ADDRESS_SEPOLIA: adminRegistryAddress,
      NEXT_PUBLIC_CAMPAIGN_FACTORY_ADDRESS_SEPOLIA: campaignFactoryAddress
    };
    
    for (const [key, value] of Object.entries(envVars)) {
      const regex = new RegExp(`^${key}=.*$`, 'm');
      if (frontendEnvContent.match(regex)) {
        frontendEnvContent = frontendEnvContent.replace(regex, `${key}=${value}`);
      } else {
        frontendEnvContent += `\n${key}=${value}`;
      }
    }
    
    fs.writeFileSync(frontendEnvPath, frontendEnvContent);
    console.log(`Frontend environment variables updated in ${frontendEnvPath}`);
  } catch (error) {
    console.error("Error updating frontend environment variables:", error);
  }
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
