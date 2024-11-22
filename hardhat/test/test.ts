import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ContractManager", function () {
  async function deployContractManagerFixture() {
    const [deployer, admin, user] = await ethers.getSigners();

    const ContractManager = await ethers.getContractFactory("ContractManager");
    const contractManager = await ContractManager.deploy(admin.address);
    //await contractManager.deployed();

    return { contractManager, deployer, admin, user };
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

  describe("Add Contract", function () {
    it("Should allow an admin to add a contract", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(contractAddress, description);

      expect(await contractManager.getDescription(contractAddress)).to.equal(description);
    });

    it("Should emit a ContractAdded event when a contract is added", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await expect(contractManager.connect(admin).addContract(contractAddress, description))
        .to.emit(contractManager, "ContractAdded")
        .withArgs(contractAddress, description);
    });

    it("Should revert if the contract address is zero", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      await expect(
        contractManager.connect(admin).addContract(ethers.ZeroAddress, "Invalid Address")
      ).to.be.revertedWith("Invalid address");
    });

    it("Should revert if the contract already exists", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(contractAddress, description);

      await expect(
        contractManager.connect(admin).addContract(contractAddress, "Duplicate Contract")
      ).to.be.revertedWith("Contract already exists");
    });
  });


  describe("Batch Add Contracts", function () {
    it("Should allow an admin to add multiple contracts in a batch", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddresses = [
        ethers.Wallet.createRandom().address,
        ethers.Wallet.createRandom().address,
      ];
      const descriptions = ["Contract 1", "Contract 2"];

      await contractManager.connect(admin).addContracts(contractAddresses, descriptions);

      for (let i = 0; i < contractAddresses.length; i++) {
        const storedDescription = await contractManager.getDescription(contractAddresses[i]);
        expect(storedDescription).to.equal(descriptions[i]);
      }
    });

    it("Should emit ContractAdded events for each added contract", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddresses = [
        ethers.Wallet.createRandom().address,
        ethers.Wallet.createRandom().address,
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

    it("Should revert if input lengths are mismatched", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddresses = [ethers.Wallet.createRandom().address];
      const descriptions = ["Contract 1", "Extra Description"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWith("Mismatched input lengths");
    });

    it("Should revert if any contract address is zero", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddresses = [
        ethers.Wallet.createRandom().address,
        ethers.ZeroAddress,
      ];
      const descriptions = ["Contract 1", "Invalid Address"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWith("Invalid address");
    });

    it("Should revert if any contract in the batch already exists", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Existing Contract";

      await contractManager.connect(admin).addContract(contractAddress, description);

      const contractAddresses = [contractAddress, ethers.Wallet.createRandom().address];
      const descriptions = ["Duplicate Contract", "New Contract"];

      await expect(
        contractManager.connect(admin).addContracts(contractAddresses, descriptions)
      ).to.be.revertedWith("Contract already exists");
    });
});

  describe("Update Description", function () {
    it("Should allow an admin to update a contract description", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Initial Description";
      const newDescription = "Updated Description";

      await contractManager.connect(admin).addContract(contractAddress, description);
      await contractManager.connect(admin).updateDescription(contractAddress, newDescription);

      expect(await contractManager.getDescription(contractAddress)).to.equal(newDescription);
    });

    it("Should emit a ContractUpdated event when a description is updated", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Initial Description";
      const newDescription = "Updated Description";

      await contractManager.connect(admin).addContract(contractAddress, description);

      await expect(contractManager.connect(admin).updateDescription(contractAddress, newDescription))
        .to.emit(contractManager, "ContractUpdated")
        .withArgs(contractAddress, newDescription);
    });

    it("Should revert if the contract does not exist", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;

      await expect(
        contractManager.connect(admin).updateDescription(contractAddress, "New Description")
      ).to.be.revertedWith("Contract does not exist");
    });
  });

  describe("Remove Contract", function () {
    it("Should allow an admin to remove a contract", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(contractAddress, description);
      await contractManager.connect(admin).removeContract(contractAddress);

      await expect(contractManager.getDescription(contractAddress)).to.be.revertedWith(
        "Contract does not exist"
      );
    });

    it("Should emit a ContractRemoved event when a contract is removed", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;
      const description = "Test Contract";

      await contractManager.connect(admin).addContract(contractAddress, description);

      await expect(contractManager.connect(admin).removeContract(contractAddress))
        .to.emit(contractManager, "ContractRemoved")
        .withArgs(contractAddress);
    });

    it("Should revert if the contract does not exist", async function () {
      const { contractManager, admin } = await loadFixture(deployContractManagerFixture);

      const contractAddress = ethers.Wallet.createRandom().address;

      await expect(contractManager.connect(admin).removeContract(contractAddress)).to.be.revertedWith(
        "Contract does not exist"
      );
    });
  });
});
