// SPDX-License-Identifier: MIT
//By Jamil hallack

pragma solidity ^0.8.20;

import "./IContractManager.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ContractManager
///@author Jamil Hallack
/// @notice Manages storage, updating, and removal of contract addresses and descriptions.
/// @dev Uses OpenZeppelin's AccessControl for role-based access and ReentrancyGuard for security against reentrancy attacks.
contract ContractManager is IContractManager, AccessControl, ReentrancyGuard {
    // Define the admin role for contract management
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Mapping to store descriptions for each contract address
    mapping(address => string) private descriptions;

    // Events
    /// @notice Emitted when a new contract is added with its description
    event ContractAdded(address indexed contractAddress, string description);

    /// @notice Emitted when an existing contract's description is updated
    event ContractUpdated(address indexed contractAddress, string newDescription);

    /// @notice Emitted when a contract is removed
    event ContractRemoved(address indexed contractAddress);

    // Custom Errors
    error InvalidAddress(); // Triggered when the provided address is not a contract
    error ContractAlreadyExists(); // Triggered when trying to add an already registered contract
    error ContractDoesNotExist(); // Triggered when the queried contract is not found
    error MismatchedInputLengths(); // Triggered when batch addition input arrays have different lengths
    error DescriptionTooLong(uint256 providedLength, uint256 maxAllowed); // Triggered when a description exceeds the allowed length
    error EmptyDescription(); // Triggered when the description is empty

    /// @notice Constructor to set the initial admin roles
    /// @param admin Address that will be granted the ADMIN_ROLE
    constructor(address admin) {
        // Assign deployer as the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant the ADMIN_ROLE to the provided admin address
        _grantRole(ADMIN_ROLE, admin);
    }

    /// @inheritdoc IContractManager
    /// @dev Ensures only admins can add contracts and validates inputs
    function addContract(address contractAddress, string calldata description)
        external
        override
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        // Validation checks for inputs
        if (contractAddress.code.length == 0) revert InvalidAddress(); // Ensure it's a contract
        if (bytes(descriptions[contractAddress]).length != 0) revert ContractAlreadyExists(); // Avoid duplicates
        if (bytes(description).length == 0) revert EmptyDescription(); // Reject empty descriptions
        if (bytes(description).length > 256) revert DescriptionTooLong(bytes(description).length, 256); // Enforce max length

        descriptions[contractAddress] = description; // Store the description
        emit ContractAdded(contractAddress, description); // Emit event
    }

    /// @notice Adds multiple contracts with descriptions in a single transaction
    /// @param contractAddresses Array of contract addresses
    /// @param descriptionsList Corresponding array of descriptions
    /// @dev Uses a loop to validate and add contracts in bulk, emitting individual events for each addition.
    function addContracts(address[] calldata contractAddresses, string[] calldata descriptionsList)
        external
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        if (contractAddresses.length != descriptionsList.length) revert MismatchedInputLengths(); // Ensure inputs match

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            string calldata description = descriptionsList[i];

            // Input validation for each contract
            if (contractAddress.code.length == 0) revert InvalidAddress();
            if (bytes(descriptions[contractAddress]).length != 0) revert ContractAlreadyExists();
            if (bytes(description).length == 0) revert EmptyDescription();
            if (bytes(description).length > 256) revert DescriptionTooLong(bytes(description).length, 256);

            descriptions[contractAddress] = description; // Store each description
            emit ContractAdded(contractAddress, description); // Emit event for each addition
        }
    }

    /// @inheritdoc IContractManager
    /// @dev Updates the description of an existing contract, ensuring it meets validation rules
    function updateDescription(address contractAddress, string calldata newDescription)
        external
        override
        onlyRole(ADMIN_ROLE)
        nonReentrant
    {
        if (bytes(descriptions[contractAddress]).length == 0) revert ContractDoesNotExist(); // Ensure contract exists
        if (bytes(newDescription).length == 0) revert EmptyDescription(); // Reject empty descriptions
        if (bytes(newDescription).length > 256) revert DescriptionTooLong(bytes(newDescription).length, 256); // Enforce max length

        descriptions[contractAddress] = newDescription; // Update the description
        emit ContractUpdated(contractAddress, newDescription); // Emit event
    }

    /// @inheritdoc IContractManager
    /// @dev Removes a contract's metadata, ensuring it exists
    function removeContract(address contractAddress) external override onlyRole(ADMIN_ROLE) nonReentrant {
        if (bytes(descriptions[contractAddress]).length == 0) revert ContractDoesNotExist(); // Ensure contract exists

        delete descriptions[contractAddress]; // Delete the entry
        emit ContractRemoved(contractAddress); // Emit event
    }

    /// @inheritdoc IContractManager
    /// @dev Retrieves the description of a registered contract
    function getDescription(address contractAddress) external view override returns (string memory) {
        if (bytes(descriptions[contractAddress]).length == 0) revert ContractDoesNotExist(); // Ensure contract exists
        return descriptions[contractAddress]; // Return the description
    }

    /// @notice Supports interface detection as per EIP-165
    /// @param interfaceId Interface identifier
    /// @return bool True if the interface is supported
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return interfaceId == type(IContractManager).interfaceId || super.supportsInterface(interfaceId);
    }
}
