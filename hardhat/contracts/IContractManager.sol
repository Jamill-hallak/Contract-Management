// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IContractManager Interface
/// @notice Interface for managing contract addresses and their descriptions
interface IContractManager {
    function addContract(address contractAddress, string calldata description) external;

    function updateDescription(address contractAddress, string calldata newDescription) external;

    function removeContract(address contractAddress) external;

    function getDescription(address contractAddress) external view returns (string memory);
}
