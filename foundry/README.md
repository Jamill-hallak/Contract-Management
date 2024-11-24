
# ContractManager (Foundry)

## Overview

This folder contains the **Foundry implementation** of the `ContractManager` smart contract. Foundry is ideal for rapid testing, precise gas profiling, and Solidity-native workflows. This implementation prioritizes efficiency and modularity for seamless integration into larger systems.

---

## Table of Contents

1. [Features](#features)
2. [Folder Structure](#folder-structure)
3. [Requirements](#requirements)
4. [How to Use](#how-to-use)
5. [Testing Summary](#testing-summary)
6. [Gas Metrics](#gas-metrics)
7. [Deployment Script](#deployment-script)
8. [Notes](#notes)

---

## Features

- **Gas Profiling**: Foundry provides detailed metrics for gas usage across all operations.
- **Role-Based Access Control**: Securely manage contract metadata with administrative roles.
- **Batch Operations**: Add multiple contracts in a single transaction to optimize gas costs.
- **Lean Testing Workflow**: Foundry's fast and lightweight framework ensures rapid iteration and feedback.

---

## Folder Structure

- **`src/`**: Contains:
  - `ContractManager.sol`: Main smart contract implementation.
  - `IContractManager.sol`: Interface for `ContractManager`.
  - `MockContract.sol`: A mock contract for testing purposes.
- **`test/`**: Solidity-based test files for validating functionality and profiling gas usage.
- **`script/`**: Scripts for deploying the contract on local or live networks.
- **`foundry.toml`**: Configuration file for Foundry, including compiler settings and dependencies.

---

## Requirements

Before using this repository, ensure the following are installed:

- **Foundry**: Foundry's toolset (`forge`, `cast`, etc.) must be installed. Install it using:
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```

- **Git**: Required to clone the repository and manage dependencies.
- **Node.js (optional)**: Needed if integrating with frontend tools.

---

## How to Use

### 1. Install Dependencies

Clone the repository and install Foundry dependencies:

```bash
git clone https://github.com/Jamill-hallak/Contract-Management.git
cd ContractManager
cd foundry
forge install
```

### 2. Compile Contracts

Compile the Solidity contracts:

```bash
forge build
```

### 3. Run Tests

Run all tests to validate the contract's functionality, gas efficiency, and error handling:

```bash
forge test
```

**Example Output**:
```bash
Running 5 tests for src/test/ContractManagerTest.t.sol
[PASS] testAddContract() (gas: 53,197)
[PASS] testAddContractsBatch() (gas: 123,187)
[PASS] testRemoveContract() (gas: 46,366)
...
Test result: ok. 45 passed; 0 failed; 0 skipped
```

### 4. Analyze Gas Usage

Gas profiling is automatically included in the test output. Focus on gas usage for critical operations like batch additions and updates to ensure efficiency.

### 5. Deploy Contract Using `DeployContractManager.s.sol`

- **Script Location**: The deployment script is located in `script/DeployContractManager.s.sol`.
- **Purpose**: Deploys the `ContractManager` contract with the desired admin address to the specified network.
- **Usage**:
  ```bash
  forge script script/DeployContractManager.s.sol --fork-url <RPC_URL> --broadcast
  ```
- Replace `<RPC_URL>` with the endpoint of your desired network (e.g., Anvil, Ethereum Mainnet, etc.).

**Example**: Deploying to a local Anvil node:
```bash
forge script script/DeployContractManager.s.sol --fork-url http://127.0.0.1:8545 --broadcast
```

- **Expected Output**: The script will deploy the contract and return the deployed address.
- Be sure to set your own --sender.

---

## Testing Summary

The Foundry test suite validates:

- **Functionality**:
  - Adding, updating, and removing contracts.
  - Retrieving metadata for specific contracts.
- **Batch Operations**:
  - Ensuring correctness and gas savings for multiple additions.
- **Error Handling**:
  - Testing invalid inputs such as empty descriptions, zero addresses, and mismatched array lengths.
- **Gas Optimization**:
  - Measuring and comparing gas costs for individual versus batch operations.

---

## Gas Metrics

Below are sample gas metrics for common operations (based on test execution):

| Operation          | Gas Usage   |
|---------------------|-------------|
| `addContract`      | **53,197**  |
| `addContracts`     | **123,187** |
| `removeContract`   | **46,366**  |

These metrics highlight the efficiency of batch operations compared to individual transactions.

---

## Notes

This Foundry implementation is part of the broader **ContractManager Project**, which provides a modular framework for managing contract metadata. For a comprehensive overview, refer to the parent repository:

- Explore alternative implementations, including Hardhat.
- Understand the design philosophy and project roadmap.
- Access advanced documentation and use cases.

[**ContractManager Parent Repository**](https://github.com/Jamill-hallak/Contract-Management)

By leveraging the parent repository, you can better understand the modular design and extend this implementation to suit your needs.
