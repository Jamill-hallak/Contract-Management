# ContractManager (Foundry)

## Overview

This folder contains the **Foundry implementation** of the `ContractManager` smart contract. Foundry is ideal for rapid testing, precise gas profiling, and Solidity-native workflows. This implementation prioritizes efficiency and modularity for seamless integration into larger systems.

---

## Features

- **Gas Profiling**: Foundry provides detailed metrics for gas usage across all operations.
- **Role-Based Access Control**: Secure contract metadata management with administrative roles.
- **Batch Operations**: Optimize gas costs by adding multiple contracts in a single transaction.
- **Lean Testing Workflow**: Foundry's fast and lightweight framework ensures rapid iteration.

---

## Folder Structure

- **`src/`**: Contains the `ContractManager.sol` and `IContractManager.sol`.
- **`test/`**: Includes Solidity-based tests for contract functionality and gas profiling.
- **`script/`**:  Deployment scripts for local and network deployments.
- **`foundry.toml`**: Foundry configuration file for testing and building.

---

## How to Use

1. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Clone Repository and Install Dependencies**:
   ```bash
   forge install
   ```

3. **Run Tests**:
   ```bash
   forge test
   ```

4. **Analyze Gas Usage**:
   Foundry tests include gas profiling for key operations. Gas metrics are displayed after each test execution.

---

## Testing Summary

The Foundry test suite ensures:
- **Functionality**: Validating adding, updating, and removing contracts.
- **Batch Operations**: Ensuring correctness and gas savings for multiple additions.
- **Error Handling**: Testing invalid inputs, including empty descriptions and mismatched arrays.
- **Gas Optimization**: Verifying that operations are as efficient as possible.

**Gas Metrics**:
- `addContract`: **53,197 gas**
- `addContracts` (batch): **123,187 gas**
- `removeContract`: **46,366 gas**

---

## Notes

For detailed contract documentation and design decisions, refer to the parent repository.
