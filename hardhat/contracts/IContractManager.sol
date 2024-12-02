// SPDX-License-Identifier: MIT
//By Jamil hallack

pragma solidity ^0.8.20;

/// @title IContractManager Interface
///@author Jamil Hallack
/// @notice Interface for managing contract addresses and their descriptions
interface IContractManager {
    function addContract(address contractAddress, string calldata description) external;
    
    function addContracts(address[] calldata contractAddresses, string[] calldata descriptionsList)
     external;

    function updateDescription(address contractAddress, string calldata newDescription) external;

    function removeContract(address contractAddress) external;

    function getDescription(address contractAddress) external view returns (string memory);

}
