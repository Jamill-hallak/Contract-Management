// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol"; // Import the Script base class from Foundry
import {ContractManager} from "../src/ContractManager.sol"; // Import the ContractManager contract
import {console} from "forge-std/console.sol"; // Import console for logging deployment details

/// @title DeployContractManager
/// @notice A deployment script for the ContractManager contract using Foundry's scripting framework
contract DeployContractManager is Script {
    /// @notice Deploys the ContractManager contract
    function run() external {
        // Define the admin address that will be granted ADMIN_ROLE during deployment
        address admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        // Start broadcasting transactions to the blockchain
        vm.startBroadcast();

        // Deploy the ContractManager contract with the specified admin address
        ContractManager contractManager = new ContractManager(admin);

        // Log the address of the deployed contract for verification
        console.log("ContractManager deployed at:", address(contractManager));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
