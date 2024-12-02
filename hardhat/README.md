
# ContractManager (Hardhat)

## Overview

This folder contains the **Hardhat implementation** of the `ContractManager` smart contract, a gas-efficient and secure solution for managing contract metadata. The Hardhat version provides a comprehensive development environment with deployment scripts, debugging tools, and extensive testing capabilities.

---

## Table of Contents

- [ContractManager (Hardhat)](#contractmanager-hardhat)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Folder Structure](#folder-structure)
  - [Requirements](#requirements)
  - [How to Use](#how-to-use)
    - [1. Clone the Repository](#1-clone-the-repository)
    - [2. Compile Contracts](#2-compile-contracts)
    - [3. Run Tests](#3-run-tests)
    - [4. Deploy Contract](#4-deploy-contract)
    - [5. Debugging](#5-debugging)
  - [Testing Summary](#testing-summary)
  - [Notes](#notes)

---

## Features

- **Role-Based Access Control**: Securely manage contract metadata with administrative roles.
- **Batch Operations**: Add multiple contracts in a single transaction to reduce gas costs.
- **Gas Optimization**: Uses lean data structures and efficient existence checks.
- **Testing and Debugging**: Includes a robust test suite and debugging support via Hardhat tools.

---

## Folder Structure

- **`contracts/`**: Contains:
  - `ContractManager.sol`: Main smart contract implementation.
  - `IContractManager.sol`: Interface for `ContractManager`.
  - `MockContract.sol`: A mock contract for testing purposes.
- **`test/`**: TypeScript test files for contract functionality, gas optimization, and security.
- **`scripts/`**: Deployment scripts for both local and live networks.
- **`hardhat.config.js`**: Configuration file for Hardhat, including network and plugin setups.

---

## Requirements

Before using this repository, ensure the following are installed:

- **Node.js**: Version 14 or later (Check with `node --version`).
- **npm**: Version 7 or later (Check with `npm --version`).
- **Hardhat**: Installed as a local dependency in the project.

## How to Use

### 1. Clone the Repository

Clone the repository and navigate to the Hardhat implementation directory:

```bash
git clone https://github.com/Jamill-hallak/Contract-Management
cd Contract-Management
cd hardhat
npm install
```


### 2. Compile Contracts

Compile the Solidity contracts using Hardhat:

```bash
npx hardhat compile
```

### 3. Run Tests

Execute the test suite to validate functionality, access control, and gas efficiency:

```bash
npx hardhat test
```

**Example Output**:
```bash
  ContractManager
    Deployment
      ✓ Should assign DEFAULT_ADMIN_ROLE to the deployer
      ✓ Should assign ADMIN_ROLE to the admin
    Add Contract
      ✓ Should allow an admin to add a contract (100ms)
      ...
```

### 4. Deploy Contract

- Update `scripts/deployContractManager.ts` to set the desired `admin` address.
- Deploy the contract to a local or specified network:

```bash
npx hardhat run scripts/deployContractManager.ts --network <network-name>
```

For local deployment (e.g., Hardhat node):

```bash
npx hardhat run scripts/deployContractManager.ts --network localhost
```

### 5. Debugging

Use Hardhat's console for debugging:

```bash
npx hardhat console --network localhost
```

Or include `console.log` statements within contracts to debug specific functionality during testing.

---

## Testing Summary

The Hardhat test suite validates:

- **Functionality**:
  - Adding, updating, and removing contracts.
  - Retrieving contract metadata.
- **Access Control**:
  - Ensures only authorized roles can perform sensitive operations.
- **Error Handling**:
  - Thoroughly tests invalid inputs and edge cases.
- **Gas Efficiency**:
  - Compares single operations versus batch operations for optimization.

**Status**: ✅ All tests passed successfully.

---

## Notes

This Hardhat implementation is a part of the larger **ContractManager Project**, a modular and extensible framework for managing contract metadata. Explore the parent repository for:

- Detailed design architecture.
- Foundry-based implementation.
- Documentation on advanced features.

Access the parent repository here:

[**ContractManager Parent Repository**](https://github.com/Jamill-hallak/Contract-Management)

By leveraging the parent repository, you can gain deeper insights into the project's goals and explore alternative implementations.
