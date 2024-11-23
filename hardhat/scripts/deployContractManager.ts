import { ethers } from "hardhat";

async function main() {
  const [deployer, admin] = await ethers.getSigners();

  console.log("Deploying ContractManager...");
  console.log("Deployer address:", deployer.address);
  console.log("Admin address:", admin.address);

  try {
    // Deploy ContractManager
    const ContractManager = await ethers.getContractFactory("ContractManager");
    const contractManager = await ContractManager.deploy(admin.address);

    // Wait for the contract to be deployed
    await contractManager.waitForDeployment();

    // Log the deployed address
    const contractAddress = await contractManager.getAddress();
    console.log("ContractManager deployed at:", contractAddress);
  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
