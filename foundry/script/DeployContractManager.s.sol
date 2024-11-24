// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ContractManager} from "../src/ContractManager.sol";
import {console} from "forge-std/console.sol";

contract DeployContractManager is Script {
    function run() external {
        address admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; 

        vm.startBroadcast(); // Start broadcasting transactions
        ContractManager contractManager = new ContractManager(admin);
        console.log("ContractManager deployed at:", address(contractManager));
        vm.stopBroadcast(); // Stop broadcasting transactions
    }
}
