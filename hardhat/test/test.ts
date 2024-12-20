//By Jamil hallack
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { calculateInterfaceId } from "./utils/calculateInterfaceId";


// Main test suite for the ContractManager contract
describe("ContractManager", function () {
  /**
   * Fixture for deploying the ContractManager contract and setting up necessary accounts.
   * This ensures that each test starts with a clean and consistent environment.
   */
  async function deployContractManagerFixture() {
    // Retrieve test signers (accounts): deployer, admin, and other users.
    const [deployer, admin, user, otherUser] = await ethers.getSigners();

    // Deploy the ContractManager contract, initializing it with the admin's address.
    const ContractManager = await ethers.getContractFactory("ContractManager");
    const contractManager = await ContractManager.deploy(admin.address);
    await contractManager.waitForDeployment();

    // Deploy a MockContract to simulate contract addresses in tests.
    const MockContract = await ethers.getContractFactory("MockContract");
    const mockContract = await MockContract.deploy();
    await mockContract.waitForDeployment();

    return { contractManager, mockContract, deployer, admin, user, otherUser };
  }

  describe("Deployment", function () {


    it("Should assign DEFAULT_ADMIN_ROLE to the deployer", async function () {
      const { contractManager, deployer } = await loadFixture(deployContractManagerFixture);

      const DEFAULT_ADMIN_ROLE = await contractManager.DEFAULT_ADMIN_ROLE();
      expect(await contractManager.hasRole(DEFAULT_ADMIN_ROLE, deployer.address)).to.be.true;
    });

    it("Should assign ADMIN_ROLE to the admin", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
      expect(await contractManager.hasRole(ADMIN_ROLE, admin.address)).to.be.true;
    });

    
  });

  describe("Interface Compliance", function () {
    it("Should support the IContractManager interface", async function () {
      const { contractManager } = await loadFixture(deployContractManagerFixture);

      const functions = [
        "addContract(address,string)",
        "addContracts(address[],string[])",
        "updateDescription(address,string)",
        "removeContract(address)",
        "getDescription(address)"
      ];
      const interfaceId = await calculateInterfaceId(functions);

      expect(await contractManager.supportsInterface(interfaceId)).to.be.true;
    });

    it("Should support the AccessControl interface", async function () {
      const { contractManager } = await loadFixture(deployContractManagerFixture);

      // AccessControl interfaceId: OpenZeppelin-defined
      const AccessControlInterfaceId = "0x7965db0b";

      expect(await contractManager.supportsInterface(AccessControlInterfaceId)).to.be.true;
    });

    it("Should return false for unsupported interfaces", async function () {
      const { contractManager } = await loadFixture(deployContractManagerFixture);

      const UnsupportedInterfaceId = "0xffffffff";
      expect(await contractManager.supportsInterface(UnsupportedInterfaceId)).to.be.false;
    });
  });


  describe("Add Contract", function () {
    it("Should allow an admin to add a contract", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      // const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(mockContract, description);

      expect(await contractManager.getDescription(mockContract)).to.equal(description);
    });

    it("Should emit a ContractAdded event when a contract is added", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      // const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await expect(contractManager.connect(admin).addContract(mockContract, description))
        .to.emit(contractManager, "ContractAdded")
        .withArgs(mockContract, description);
    });
    it("Should allow re-adding a contract after removal", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);
    
      const description = "Test Contract";
    
      // Add and remove the contract
      await contractManager.connect(admin).addContract(mockContract, description);
      await contractManager.connect(admin).removeContract(mockContract);
    
      // Re-add the same contract
      await contractManager.connect(admin).addContract(mockContract, "New Description");
      expect(await contractManager.getDescription(mockContract)).to.equal("New Description");
    });
    

    it("Should revert if the contract address is zero", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      await expect(
        contractManager.connect(admin).addContract(ethers.ZeroAddress, "Invalid Address")
      ).to.be.revertedWithCustomError(contractManager, "InvalidAddress");
    });

    it("Should revert if the contract already exists", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      // const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(mockContract, description);

      await expect(
        contractManager.connect(admin).addContract(mockContract, "Duplicate Contract")
      ).to.be.revertedWithCustomError(contractManager, "ContractAlreadyExists");
    });

    it("Should revert if the address is not a deployed contract", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);
  
      const randomAddress = ethers.Wallet.createRandom().address;
  
      await expect(
          contractManager.connect(admin).addContract(randomAddress, "Invalid Contract")
      ).to.be.revertedWithCustomError(contractManager, "InvalidAddress");
  });

  it("Should revert if the description is empty", async function () {
    const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

    const emptyDescription = "";

    await expect(
        contractManager.connect(admin).addContract(mockContract, emptyDescription)
    ).to.be.revertedWithCustomError(contractManager, "EmptyDescription");
});

it("Should revert if the description exceeds the maximum length", async function () {
    const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

    const longDescription = "a".repeat(257); // 257 characters (1 more than the limit)

    await expect(
        contractManager.connect(admin).addContract(mockContract, longDescription)
    ).to.be.revertedWithCustomError(contractManager, "DescriptionTooLong")
        .withArgs(257, 256);
});


  it("Should revert if a non-admin tries to add a contract", async function () {
    const { contractManager, mockContract, user } = await loadFixture(deployContractManagerFixture);

    const description = "Unauthorized Contract";

    await expect(
      contractManager.connect(user).addContract(mockContract, description)
    ).to.be.revertedWithCustomError(contractManager, "AccessControlUnauthorizedAccount")
      .withArgs(user.address, ethers.id("ADMIN_ROLE"));
  });
    
  });


  describe("Batch Add Contracts", function () {
    
    it("Should allow an admin to add multiple contracts in a batch", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      // Deploy a MockContract for testing
    const MockContract2 = await ethers.getContractFactory("MockContract");
    const mockContract2 = await MockContract2.deploy();
    await mockContract2.waitForDeployment();
      const contractAddresses = [
        mockContract,
        mockContract2,
      ];
      const descriptions = ["Contract 1", "Contract 2"];

      await contractManager.connect(admin).addContracts(contractAddresses, descriptions);

      for (let i = 0; i < contractAddresses.length; i++) {
        const storedDescription = await contractManager.getDescription(contractAddresses[i]);
        expect(storedDescription).to.equal(descriptions[i]);
      }
    });

    it("Should emit ContractAdded events for each added contract", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      // Deploy a MockContract for testing
      const MockContract2 = await ethers.getContractFactory("MockContract");
      const mockContract2 = await MockContract2.deploy();
      await mockContract2.waitForDeployment();
        const contractAddresses = [
          mockContract,
          mockContract2,
        ];
      const descriptions = ["Contract 1", "Contract 2"];

      const tx = await contractManager.connect(admin).addContracts(contractAddresses, descriptions);

      await expect(tx)
        .to.emit(contractManager, "ContractAdded")
        .withArgs(contractAddresses[0], descriptions[0]);

      await expect(tx)
        .to.emit(contractManager, "ContractAdded")
        .withArgs(contractAddresses[1], descriptions[1]);
    });

    it("Should compare gas usage for single vs batch additions", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);
    
      // Deploy mock contracts for testing
      const MockContract1 = await ethers.getContractFactory("MockContract");
      const mockContract1 = await MockContract1.deploy();
      await mockContract1.waitForDeployment();
      
    
      const contractAddresses = [
         mockContract,
         mockContract1
      ];
      const descriptions = ["Contract 1", "Contract 2"];
    
      // Single additions (add two contracts one by one)
      const singleTx1 = await contractManager.connect(admin).addContract(contractAddresses[0], descriptions[0]);
      const singleReceipt1 = await singleTx1.wait();
      const singleGasUsed1 = singleReceipt1.gasUsed; // Gas used for Tx1

    
      const singleTx2 = await contractManager.connect(admin).addContract(contractAddresses[1], descriptions[1]);
      const singleReceipt2 = await singleTx2.wait();
      const singleGasUsed2 = singleReceipt2.gasUsed; // Gas used for Tx2

      // Total gas used for single additions
      const totalSingleGasUsed = singleGasUsed1+singleGasUsed2;
      console.log("       Total gas used for single additions:", totalSingleGasUsed.toString());
    
      // Remove the contracts one by one
      await contractManager.connect(admin).removeContract(contractAddresses[0]);
      await contractManager.connect(admin).removeContract(contractAddresses[1]);
    
      // Batch addition (add both contracts in a single transaction)
      const batchTx = await contractManager.connect(admin).addContracts(contractAddresses, descriptions);
      const batchReceipt = await batchTx.wait();
    
      console.log("       Gas used for batch addition:", batchReceipt.gasUsed.toString());
    
      // Assertions for gas usage (optional)
      expect(batchReceipt.gasUsed).to.be.below(totalSingleGasUsed, "Batch addition should be more gas-efficient");
    });
    

    it("Should revert if input lengths are mismatched", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddresses = [ethers.Wallet.createRandom().address];
      const descriptions = ["Contract 1", "Extra Description"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "MismatchedInputLengths");

    });

    it("Should revert if any contract address is zero", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddresses = [
        mockContract,
        ethers.ZeroAddress,
      ];
      const descriptions = ["Contract 1", "Invalid Address"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "InvalidAddress");
    });

    it("Should revert if any contract in the batch already exists", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      
      const description = "Existing Contract";

      await contractManager.connect(admin).addContract(mockContract, description);

      const contractAddresses = [mockContract, mockContract];
      const descriptions = ["Duplicate Contract", "New Contract"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "ContractAlreadyExists");
    });

    it("Should revert if any address in the batch is not a deployed contract", async function () {
      const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const randomAddress = ethers.Wallet.createRandom().address;
      const contractAddresses = [
        mockContract,
        randomAddress,
      ];
      const descriptions = ["Contract 1", "Invalid Contract"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "InvalidAddress");
    });


    it("Should revert if one of the descriptions is empty", async function () {
      const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const MockContract2 = await ethers.getContractFactory("MockContract");
      const mockContract2 = await MockContract2.deploy();
      await mockContract2.waitForDeployment();

      const contractAddresses = [mockContract, mockContract2];
      const descriptions = ["Valid Description", ""]; // One description is empty

      await expect(
          contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "EmptyDescription");
  });

  it("Should revert if one of the descriptions exceeds the maximum length", async function () {
      const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const MockContract2 = await ethers.getContractFactory("MockContract");
      const mockContract2 = await MockContract2.deploy();
      await mockContract2.waitForDeployment();

      const longDescription = "a".repeat(257); // 257 characters (1 more than the limit)
      const contractAddresses = [mockContract, mockContract2];
      const descriptions = ["Valid Description", longDescription]; // One description is too long

      await expect(
          contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "DescriptionTooLong")
          .withArgs(257, 256);
  });
  
    it("Should revert if a non-admin tries to add multiple contracts in a batch", async function () {
      const { contractManager, mockContract, user } = await loadFixture(deployContractManagerFixture);

      const MockContract1 = await ethers.getContractFactory("MockContract");
      const mockContract1 = await MockContract1.deploy();
      await mockContract1.waitForDeployment();

      const contractAddresses = [
        mockContract,
        mockContract1
      ];
      const descriptions = ["Contract 1", "Contract 2"];

      await expect(
        contractManager.connect(user).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWithCustomError(contractManager, "AccessControlUnauthorizedAccount")
        .withArgs(user.address, ethers.id("ADMIN_ROLE"));
    });


   
    
});

  describe("Update Description", function () {
    it("Should allow an admin to update a contract description", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const description = "Initial Description";
      const newDescription = "Updated Description";

      await contractManager.connect(admin).addContract(mockContract, description);
      await contractManager.connect(admin).updateDescription(mockContract, newDescription);

      expect(await contractManager.getDescription(mockContract)).to.equal(newDescription);
    });

    it("Should emit a ContractUpdated event when a description is updated", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const description = "Initial Description";
      const newDescription = "Updated Description";

      await contractManager.connect(admin).addContract(mockContract, description);

      await expect(contractManager.connect(admin).updateDescription(mockContract, newDescription))
        .to.emit(contractManager, "ContractUpdated")
        .withArgs(mockContract, newDescription);
    });

    it("Should revert if the contract does not exist", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;

      await expect(
        contractManager.connect(admin).updateDescription(contractAddress, "New Description")
      ).to.be.revertedWithCustomError(contractManager, "ContractDoesNotExist");

    });

    it("Should revert if the new description is empty", async function () {
      const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const description = "Initial Description";
      const emptyDescription = "";

      // Add a valid contract first
      await contractManager.connect(admin).addContract(mockContract, description);

      // Attempt to update with an empty description
      await expect(
          contractManager.connect(admin).updateDescription(mockContract, emptyDescription)
      ).to.be.revertedWithCustomError(contractManager, "EmptyDescription");
  });

  it("Should revert if the new description exceeds the maximum length", async function () {
      const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

      const description = "Initial Description";
      const longDescription = "a".repeat(257); // 257 characters (1 more than the limit)

      // Add a valid contract first
      await contractManager.connect(admin).addContract(mockContract, description);

      // Attempt to update with a long description
      await expect(
          contractManager.connect(admin).updateDescription(mockContract, longDescription)
      ).to.be.revertedWithCustomError(contractManager, "DescriptionTooLong")
          .withArgs(257, 256); // Check the exact error arguments
  });

    it("Should revert if a non-admin tries to update the contract description", async function () {
      const { contractManager, mockContract, admin, user } = await loadFixture(deployContractManagerFixture);

      // Add contract with admin first
      const description = "Initial Description";
      await contractManager.connect(admin).addContract(mockContract, description);

      const newDescription = "Unauthorized Update";

      // Expect revert with custom error for unauthorized account
      await expect(
        contractManager.connect(user).updateDescription(mockContract, newDescription)
      ).to.be.revertedWithCustomError(contractManager, "AccessControlUnauthorizedAccount")
        .withArgs(user.address, ethers.id("ADMIN_ROLE"));
    });
  });

  describe("Remove Contract", function () {
    it("Should allow an admin to remove a contract", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);

      
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(mockContract, description);
      await contractManager.connect(admin).removeContract(mockContract);

      await expect(contractManager.getDescription(mockContract)
    ).to.be.revertedWithCustomError(contractManager, "ContractDoesNotExist");

    });

    it("Should emit a ContractRemoved event when a contract is removed", async function () {
      const { contractManager, mockContract,admin } = await loadFixture(deployContractManagerFixture);

      const description = "Test Contract";

      await contractManager.connect(admin).addContract(mockContract, description);

      await expect(contractManager.connect(admin).removeContract(mockContract))
        .to.emit(contractManager, "ContractRemoved")
        .withArgs(mockContract);
    });

    it("Should clear the state after removing a contract", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);
  
      const description = "Test Contract";
  
      await contractManager.connect(admin).addContract(mockContract, description);
      await contractManager.connect(admin).removeContract(mockContract);
  
      // Ensure state is cleared
      const descriptionExists = await contractManager
        .getDescription(mockContract)
        .catch(() => false); // Catch revert and return false
      expect(descriptionExists).to.be.false;
    });
    it("Should revert if the contract does not exist", async function () {
      const { contractManager,mockContract, admin } = await loadFixture(deployContractManagerFixture);


      await expect(contractManager.connect(admin).removeContract(mockContract)
    ).to.be.revertedWithCustomError(contractManager, "ContractDoesNotExist");

    });
    
    
    it("Should revert if trying to remove a zero address", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);
  
      await expect(contractManager.connect(admin).removeContract(ethers.ZeroAddress)).to.be.revertedWithCustomError(
        contractManager,
        "ContractDoesNotExist"
      );
    });
    it("Should revert if a non-admin tries to remove a contract", async function () {
      const { contractManager,mockContract, user, admin } = await loadFixture(deployContractManagerFixture);
    
      const description = "Test Contract";
    
      // Add a contract as admin
      await contractManager.connect(admin).addContract(mockContract, description);
    
      // Attempt to remove the contract as a non-admin
      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
      await expect(contractManager.connect(user).removeContract(mockContract))
        .to.be.revertedWithCustomError(contractManager, "AccessControlUnauthorizedAccount")
        .withArgs(user.address, ADMIN_ROLE); 
    });
   
  
  });


  describe("Get Description", function () {

    it("Should return the correct description for an existing contract", async function () {
        const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

        const description = "Existing Contract Description";
        await contractManager.connect(admin).addContract(mockContract, description);

        const retrievedDescription = await contractManager.getDescription(mockContract);
        expect(retrievedDescription).to.equal(description);
    });

    it("Should revert if the contract does not exist", async function () {
        const { contractManager } = await loadFixture(deployContractManagerFixture);

        const nonExistentContract = ethers.Wallet.createRandom().address;

        await expect(
            contractManager.getDescription(nonExistentContract)
        ).to.be.revertedWithCustomError(contractManager, "ContractDoesNotExist");
    });

    it("Should revert if the contract has been removed", async function () {
        const { contractManager, mockContract, admin } = await loadFixture(deployContractManagerFixture);

        const description = "Contract to Remove";
        await contractManager.connect(admin).addContract(mockContract, description);

        // Remove the contract
        await contractManager.connect(admin).removeContract(mockContract);

        await expect(
            contractManager.getDescription(mockContract)
        ).to.be.revertedWithCustomError(contractManager, "ContractDoesNotExist");
    });


});
  
  describe("Role Management", function () {
    it("Should allow an admin to grant ADMIN_ROLE to a user", async function () {
      const { contractManager, deployer, user } = await loadFixture(deployContractManagerFixture);
  
      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
  
      // Use the deployer (has DEFAULT_ADMIN_ROLE) to grant ADMIN_ROLE
      await contractManager.connect(deployer).grantRole(ADMIN_ROLE, user.address);
      expect(await contractManager.hasRole(ADMIN_ROLE, user.address)).to.be.true;
    });
  
    it("Should allow an admin to revoke ADMIN_ROLE from a user", async function () {
      const { contractManager, deployer, user } = await loadFixture(deployContractManagerFixture);
  
      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
  
      // Grant and revoke ADMIN_ROLE
      await contractManager.connect(deployer).grantRole(ADMIN_ROLE, user.address);
      await contractManager.connect(deployer).revokeRole(ADMIN_ROLE, user.address);
      expect(await contractManager.hasRole(ADMIN_ROLE, user.address)).to.be.false;
    });
    
    it("Should only allow an admin to add and remove multiple users with ADMIN_ROLE", async function () {
      const { contractManager, deployer, user, otherUser } = await loadFixture(deployContractManagerFixture);
  
      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
  
      // Add multiple users with ADMIN_ROLE
      await contractManager.connect(deployer).grantRole(ADMIN_ROLE, user.address);
      await contractManager.connect(deployer).grantRole(ADMIN_ROLE, otherUser.address);
  
      // Verify both users now have ADMIN_ROLE
      expect(await contractManager.hasRole(ADMIN_ROLE, user.address)).to.be.true;
      expect(await contractManager.hasRole(ADMIN_ROLE, otherUser.address)).to.be.true;
  
      // Revoke ADMIN_ROLE from both users
      await contractManager.connect(deployer).revokeRole(ADMIN_ROLE, user.address);
      await contractManager.connect(deployer).revokeRole(ADMIN_ROLE, otherUser.address);
  
      // Verify neither user has ADMIN_ROLE
      expect(await contractManager.hasRole(ADMIN_ROLE, user.address)).to.be.false;
      expect(await contractManager.hasRole(ADMIN_ROLE, otherUser.address)).to.be.false;
    });

    it("Should revert if a non-admin tries to grant a role", async function () {
      const { contractManager, user, otherUser } = await loadFixture(deployContractManagerFixture);
    
      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
    
      await expect(
        contractManager.connect(user).grantRole(ADMIN_ROLE, otherUser.address)
      ).to.be.revertedWithCustomError(
        contractManager,
        "AccessControlUnauthorizedAccount"
      ).withArgs(user.address, ethers.ZeroHash); // `DEFAULT_ADMIN_ROLE` is the required role
    });
    
  
    it("Should revert if a non-admin tries to revoke a role", async function () {
      const { contractManager, deployer, user } = await loadFixture(deployContractManagerFixture);
    
      const ADMIN_ROLE = await contractManager.ADMIN_ROLE();
    
      // Grant ADMIN_ROLE to the user
      await contractManager.connect(deployer).grantRole(ADMIN_ROLE, user.address);
    
      await expect(
        contractManager.connect(user).revokeRole(ADMIN_ROLE, deployer.address)
      ).to.be.revertedWithCustomError(
        contractManager,
        "AccessControlUnauthorizedAccount"
      ).withArgs(user.address, ethers.ZeroHash); // `DEFAULT_ADMIN_ROLE` is the required role
    });
     
  });
  
});
