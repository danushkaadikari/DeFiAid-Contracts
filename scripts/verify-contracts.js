// Script to verify DeFiAid contracts on Etherscan
const hre = require("hardhat");
require("dotenv").config();
const fs = require("fs");

async function main() {
  // Get network name
  const network = hre.network.name;
  console.log(`Verifying contracts on ${network}...`);
  
  // Check if deployment file exists
  const deploymentPath = `./deployments/${network}.json`;
  if (!fs.existsSync(deploymentPath)) {
    throw new Error(`Deployment file not found: ${deploymentPath}. Please deploy contracts first.`);
  }
  
  // Read deployment information
  const deploymentInfo = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'));
  console.log(`Loaded deployment information from ${deploymentPath}`);
  
  // Get contract addresses
  const campaignFactoryAddress = deploymentInfo.campaignFactory;
  const adminRegistryAddress = deploymentInfo.adminRegistry;
  
  if (!campaignFactoryAddress || !adminRegistryAddress) {
    throw new Error("Contract addresses not found in deployment file.");
  }
  
  console.log(`CampaignFactory address: ${campaignFactoryAddress}`);
  console.log(`AdminRegistry address: ${adminRegistryAddress}`);
  
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
  
  // Parse admin addresses from environment variable
  const adminAddresses = process.env.ADMIN_ADDRESSES.split(',');
  
  // Verify CampaignFactory contract
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
  
  // Verify AdminRegistry contract
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

// Execute the verification
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
