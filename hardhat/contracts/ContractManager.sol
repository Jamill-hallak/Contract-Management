// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IContractManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title ContractManager
/// @notice Manages storage, updating, and removal of contract addresses and descriptions
contract ContractManager is IContractManager, AccessControl, UUPSUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => string) private descriptions;

    event ContractAdded(address indexed contractAddress, string description);
    event ContractUpdated(address indexed contractAddress, string newDescription);
    event ContractRemoved(address indexed contractAddress);

    /// @notice Constructor assigns admin roles and sets the trusted forwarder
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @inheritdoc IContractManager
    function addContract(address contractAddress, string calldata description) external override onlyRole(ADMIN_ROLE) {
        require(contractAddress != address(0), "Invalid address");
        require(bytes(descriptions[contractAddress]).length == 0, "Contract already exists");

        descriptions[contractAddress] = description;
        emit ContractAdded(contractAddress, description);
    }


    /// @notice Adds multiple contracts in a single transaction
    /// @param contractAddresses The list of contract addresses
    /// @param descriptionsList The corresponding list of descriptions
    function addContracts(address[] calldata contractAddresses, string[] calldata descriptionsList)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(contractAddresses.length == descriptionsList.length, "Mismatched input lengths");

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            string calldata description = descriptionsList[i];

            require(contractAddress != address(0), "Invalid address");
            require(bytes(descriptions[contractAddress]).length == 0, "Contract already exists");

            descriptions[contractAddress] = description;
            emit ContractAdded(contractAddress, description);
        }
    }

    /// @inheritdoc IContractManager
    function updateDescription(address contractAddress, string calldata newDescription)
        external
        override
        onlyRole(ADMIN_ROLE)
    {
        require(bytes(descriptions[contractAddress]).length > 0, "Contract does not exist");

        descriptions[contractAddress] = newDescription;
        emit ContractUpdated(contractAddress, newDescription);
    }

    /// @inheritdoc IContractManager
    function removeContract(address contractAddress) external override onlyRole(ADMIN_ROLE) {
        require(bytes(descriptions[contractAddress]).length > 0, "Contract does not exist");

        delete descriptions[contractAddress];
        emit ContractRemoved(contractAddress);
    }

    /// @inheritdoc IContractManager
    function getDescription(address contractAddress) external view override returns (string memory) {
        require(bytes(descriptions[contractAddress]).length > 0, "Contract does not exist");
        return descriptions[contractAddress];
    }

    /// @notice Supports interface detection (EIP-165)
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return interfaceId == type(IContractManager).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Authorizes upgrades (EIP-1967/UUPS)
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

   
}
