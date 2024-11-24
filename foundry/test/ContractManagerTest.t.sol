// SPDX-License-Identifier: MIT
//By Jamil hallack

pragma solidity ^0.8.20;

// Import required testing and contract files
import {Test, console} from "forge-std/Test.sol"; // Foundry's standard test utilities
import {ContractManager} from "../src/ContractManager.sol"; // The ContractManager contract being tested
import {MockContract} from "../src/MockContract.sol"; // A simple mock contract used for testing
import {IContractManager} from "../src/IContractManager.sol"; // Interface to validate compliance

/// @title ContractManagerTest
/// @notice A comprehensive suite of unit tests for the ContractManager smart contract
/// @dev Tests cover functionality, access control, batch processing, event emissions, and edge cases
contract ContractManagerTest is Test {
    // State variables for test environment
    ContractManager private contractManager; // Instance of ContractManager being tested
    MockContract private mockContract1; // Mock contract for testing add operations
    MockContract private mockContract2; // Second mock contract for batch operations
    address private deployer; // Address representing the deployer of the contract
    address private admin; // Address granted the ADMIN_ROLE
    address private user; // General user address without special privileges
    address private otherUser; // Another general user for role testing
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Predefined constant for the admin role
    bool consoleloggedSetup; // Flag to track setup logging (optional)

    // Events from the ContractManager contract, included for testing event emissions
    event ContractAdded(address indexed contractAddress, string description);
    event ContractUpdated(address indexed contractAddress, string newDescription);
    event ContractRemoved(address indexed contractAddress);

    /// @notice Sets up the testing environment
    /// @dev Deploys the ContractManager and mock contracts, initializes roles, and assigns admin privileges
    function setUp() public {
        // Initialize key addresses
        deployer = address(this);
        admin = makeAddr("admin");
        user = makeAddr("user");
        otherUser = makeAddr("otherUser");

        // Deploy the ContractManager with `admin` as the ADMIN_ROLE holder
        contractManager = new ContractManager(admin);

        // Deploy two mock contracts for testing
        mockContract1 = new MockContract();
        mockContract2 = new MockContract();

        // Assign DEFAULT_ADMIN_ROLE to the deployer
        vm.prank(deployer); // Simulate `deployer` as the caller
        contractManager.grantRole(contractManager.DEFAULT_ADMIN_ROLE(), admin);
    }

    // === Deployment Tests ===

    /// @notice Tests if the DEFAULT_ADMIN_ROLE is assigned to the deployer
    function testDefaultAdminRoleAssigned() public view {
        console.log("Testing if DEFAULT_ADMIN_ROLE is assigned to the deployer...");
        bytes32 defaultAdminRole = contractManager.DEFAULT_ADMIN_ROLE();
        assertTrue(contractManager.hasRole(defaultAdminRole, deployer), "Deployer should have DEFAULT_ADMIN_ROLE");
    }

    /// @notice Tests if the ADMIN_ROLE is correctly assigned to the `admin` address
    function testAdminRoleAssigned() public view {
        console.log("Testing if ADMIN_ROLE is assigned to the admin...");
        assertTrue(contractManager.hasRole(ADMIN_ROLE, admin), "Admin should have ADMIN_ROLE");
    }

    /// @notice Verifies that a non-existent role is not incorrectly assigned to an address
    function testNonExistentRoleCheck() public view {
        console.log("Testing if a non-existent role is not assigned...");
        assertFalse(
            contractManager.hasRole(keccak256("UNKNOWN_ROLE"), admin), "Unknown role should not be assigned to admin"
        );
    }

    // === Interface Compliance Tests ===

    /// @notice Confirms that the ContractManager supports the IContractManager interface
    function testSupportsIContractManager() public view {
        console.log("Testing if ContractManager supports IContractManager interface...");
        bytes4 interfaceId = type(IContractManager).interfaceId;
        assertTrue(
            contractManager.supportsInterface(interfaceId), "ContractManager should support IContractManager interface"
        );
    }

    /// @notice Confirms that the ContractManager supports the AccessControl interface
    function testSupportsAccessControl() public view {
        console.log("Testing if ContractManager supports AccessControl interface...");
        bytes4 accessControlInterfaceId = 0x7965db0b; // Interface ID for AccessControl
        assertTrue(
            contractManager.supportsInterface(accessControlInterfaceId),
            "ContractManager should support AccessControl interface"
        );
    }

    /// @notice Verifies that an invalid interface ID is not supported
    function testDoesNotSupportInvalidInterface() public view {
        console.log("Testing if ContractManager does not support an invalid interface...");
        bytes4 invalidInterfaceId = 0xffffffff; // Invalid interface ID
        assertFalse(
            contractManager.supportsInterface(invalidInterfaceId),
            "ContractManager should not support invalid interface"
        );
    }

    // === Adding Contracts ===

    /// @notice Tests if an admin can add a contract with a valid description
    function testAdminCanAddContract() public {
        console.log("Testing if an admin can add a contract...");
        vm.prank(admin); // Simulate admin as caller
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Verify that the description was successfully added
        string memory description = contractManager.getDescription(address(mockContract1));
        assertEq(description, "Test Contract", "Contract description should match");
    }

    /// @notice Tests if the `ContractAdded` event is emitted when a contract is added
    function testEmitContractAddedEvent() public {
        console.log("Testing if ContractAdded event is emitted when adding a contract...");
        vm.prank(admin); // Simulate admin as caller
        vm.expectEmit(true, true, true, true); // Expect the event to be emitted
        emit ContractAdded(address(mockContract1), "Test Contract"); // Expected event
        contractManager.addContract(address(mockContract1), "Test Contract");
    }

    /// @notice Tests if adding a zero address as a contract reverts
    function testCannotAddZeroAddress() public {
        console.log("Testing if adding a zero address reverts...");
        vm.prank(admin); // Simulate admin as caller
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()")); // Expect revert with specific error
        contractManager.addContract(address(0), "Invalid Contract");
    }

    /// @notice Tests if adding a duplicate contract reverts
    function testCannotAddAlreadyExistingContract() public {
        console.log("Testing if adding an already existing contract reverts...");
        vm.prank(admin); // Add the contract for the first time
        contractManager.addContract(address(mockContract1), "Test Contract");
        vm.prank(admin); // Try adding the same contract again
        vm.expectRevert(abi.encodeWithSignature("ContractAlreadyExists()")); // Expect revert
        contractManager.addContract(address(mockContract1), "Duplicate Contract");
    }

    /// @notice Tests if adding a non-contract address reverts
    function testCannotAddNonContractAddress() public {
        console.log("Testing if adding a non-contract address reverts...");
        address randomAddress = makeAddr("random"); // Generate a non-contract address
        vm.prank(admin); // Simulate admin as caller
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()")); // Expect revert with InvalidAddress error
        contractManager.addContract(randomAddress, "Invalid Contract");
    }

    /// @notice Tests if adding a contract with an empty description reverts
    function testCannotAddEmptyDescription() public {
        console.log("Testing if adding a contract with an empty description reverts...");

        // Simulate the admin adding a contract with an empty description
        vm.prank(admin);

        // Expect the contract to revert with the `EmptyDescription` error
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("EmptyDescription()"))));

        // Attempt to add the contract
        contractManager.addContract(address(mockContract1), "");
    }

    /// @notice Tests if adding a contract with a description exceeding 256 characters reverts
    function testCannotAddOverLimitDescription() public {
        console.log("Testing if adding a contract with a description exceeding 256 characters reverts...");

        // Generate a 257-character string to simulate over-limit input
        string memory longDescription = new string(257);

        // Simulate the admin adding a contract with an over-limit description
        vm.prank(admin);

        // Expect the contract to revert with the `DescriptionTooLong` error and verify the parameters
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("DescriptionTooLong(uint256,uint256)")),
                257, // Provided length
                256 // Max allowed length
            )
        );

        // Attempt to add the contract
        contractManager.addContract(address(mockContract1), longDescription);
    }

    /// @notice Tests if a non-admin cannot add a contract
    function testNonAdminCannotAddContract() public {
        console.log("Testing if a non-admin cannot add a contract...");

        // Simulate a non-admin user attempting to add a contract
        vm.prank(user);

        // Expect the contract to revert with an `AccessControlUnauthorizedAccount` error
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                user, // The unauthorized user
                keccak256("ADMIN_ROLE") // The required role
            )
        );

        // Attempt to add the contract
        contractManager.addContract(address(mockContract1), "Unauthorized Contract");
    }

    /// @notice Tests if a contract can be re-added after being removed
    function testReAddContractAfterRemoval() public {
        console.log("Testing if a contract can be re-added after removal...");

        // Step 1: Admin adds the contract
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Step 2: Admin removes the contract
        vm.prank(admin);
        contractManager.removeContract(address(mockContract1));

        // Step 3: Admin re-adds the same contract
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Re-Added Contract");

        // Step 4: Verify that the new description is stored correctly
        string memory newDescription = contractManager.getDescription(address(mockContract1));
        assertEq(newDescription, "Re-Added Contract", "State should be clean after re-adding the contract");
    }

    // === Removing Contracts ===

    /// @notice Tests if an admin can successfully remove a contract
    function testAdminCanRemoveContract() public {
        console.log("Testing if an admin can remove a contract...");

        // Admin adds the contract
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Admin removes the contract
        vm.prank(admin);
        contractManager.removeContract(address(mockContract1));

        // Verify that querying the removed contract reverts with `ContractDoesNotExist`
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.getDescription(address(mockContract1));
    }

    /// @notice Tests if the `ContractRemoved` event is emitted when a contract is removed
    function testEmitContractRemovedEvent() public {
        console.log("Testing if ContractRemoved event is emitted when removing a contract...");

        // Admin adds the contract
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Expect the `ContractRemoved` event to be emitted
        vm.prank(admin);
        vm.expectEmit(true, true, true, true); // Check all parameters of the event
        emit ContractRemoved(address(mockContract1)); // Expected event

        // Admin removes the contract
        contractManager.removeContract(address(mockContract1));
    }

    /// @notice Tests if removing a non-existent contract reverts
    function testCannotRemoveNonExistentContract() public {
        console.log("Testing if removing a non-existent contract reverts...");

        // Attempt to remove a contract that hasn't been added
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.removeContract(address(mockContract1));
    }

    /// @notice Tests if removing a zero address reverts
    function testCannotRemoveZeroAddress() public {
        console.log("Testing if removing a zero address reverts...");

        // Attempt to remove the zero address
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.removeContract(address(0));
    }

    /// @notice Tests if a non-admin cannot remove a contract
    function testNonAdminCannotRemoveContract() public {
        console.log("Testing if a non-admin cannot remove a contract...");

        // Admin adds the contract
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Simulate a non-admin user attempting to remove the contract
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                user, // The unauthorized user
                keccak256("ADMIN_ROLE") // The required role
            )
        );

        // Attempt to remove the contract
        contractManager.removeContract(address(mockContract1));
    }

    function testStateClearingAfterRemoveContract() public {
        console.log("Testing if the state is cleared after removing a contract...");

        // Step 1: Admin adds a contract
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Verify that the contract exists and the description is stored
        string memory description = contractManager.getDescription(address(mockContract1));
        assertEq(description, "Test Contract", "Description should be present before removal");

        // Step 2: Admin removes the contract
        vm.prank(admin);
        contractManager.removeContract(address(mockContract1));

        // Step 3: Ensure querying the removed contract reverts with ContractDoesNotExist()
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.getDescription(address(mockContract1));
    }

    // === Updating Descriptions ===

    /// @notice Tests if an admin can successfully update a contract description
    function testAdminCanUpdateDescription() public {
        console.log("Testing if an admin can update a contract description...");

        // Step 1: Admin adds a contract with an initial description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Initial Description");

        // Step 2: Admin updates the description of the added contract
        vm.prank(admin);
        contractManager.updateDescription(address(mockContract1), "Updated Description");

        // Step 3: Verify that the description has been updated successfully
        string memory updatedDescription = contractManager.getDescription(address(mockContract1));
        assertEq(updatedDescription, "Updated Description", "Contract description should be updated");
    }

    /// @notice Tests if the `ContractUpdated` event is emitted when updating a description
    function testEmitContractUpdatedEvent() public {
        console.log("Testing if ContractUpdated event is emitted when updating a description...");

        // Step 1: Admin adds a contract with an initial description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Initial Description");

        // Step 2: Expect the `ContractUpdated` event to be emitted when the description is updated
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ContractUpdated(address(mockContract1), "Updated Description");

        // Step 3: Admin updates the description of the contract
        contractManager.updateDescription(address(mockContract1), "Updated Description");
    }

    /// @notice Tests if updating the description of a non-existent contract reverts
    function testCannotUpdateDescriptionForNonExistentContract() public {
        console.log("Testing if updating a non-existent contract reverts...");

        // Attempt to update the description of a contract that has not been added
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.updateDescription(address(mockContract1), "Updated Description");
    }

    /// @notice Tests if updating a contract to an empty description reverts
    function testCannotUpdateToEmptyDescription() public {
        console.log("Testing if updating a contract to an empty description reverts...");

        // Step 1: Admin adds a contract with a valid description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Valid Description");

        // Step 2: Attempt to update the contract with an empty description
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("EmptyDescription()"))));
        contractManager.updateDescription(address(mockContract1), "");
    }

    /// @notice Tests if updating a contract to a description exceeding 256 characters reverts
    function testCannotUpdateToOverLimitDescription() public {
        console.log("Testing if updating a contract to a description exceeding 256 characters reverts...");

        // Step 1: Admin adds a contract with a valid description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Valid Description");

        // Step 2: Generate a 257-character string to simulate an over-limit input
        string memory longDescription = new string(257);

        // Step 3: Attempt to update the contract with the over-limit description
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("DescriptionTooLong(uint256,uint256)")),
                257, // Provided length
                256 // Max allowed length
            )
        );
        contractManager.updateDescription(address(mockContract1), longDescription);
    }

    /// @notice Tests if a non-admin cannot update a contract's description
    function testNonAdminCannotUpdateDescription() public {
        console.log("Testing if a non-admin cannot update a contract description...");

        // Step 1: Admin adds a contract with an initial description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Initial Description");

        // Step 2: Simulate a non-admin user attempting to update the description
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                user, // Unauthorized user
                keccak256("ADMIN_ROLE") // Required role for updating descriptions
            )
        );

        // Step 3: Attempt to update the description
        contractManager.updateDescription(address(mockContract1), "Unauthorized Update");
    }

    // === Batch adding  === ///

    /// @notice Tests if an admin can add multiple contracts in a single batch
    function testAdminCanAddMultipleContracts() public {
        console.log("Testing if an admin can add multiple contracts in a batch...");

        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Contract 2";

        // Simulate admin action
        vm.prank(admin);
        contractManager.addContracts(addresses, descriptions);

        // Assertions
        assertEq(
            contractManager.getDescription(address(mockContract1)),
            "Contract 1",
            "Description of Contract 1 should match"
        );
        assertEq(
            contractManager.getDescription(address(mockContract2)),
            "Contract 2",
            "Description of Contract 2 should match"
        );
    }

    /// @notice Tests if `ContractAdded` events are emitted for each contract in a batch

    function testEmitContractAddedEventsForBatch() public {
        console.log("Testing if ContractAdded events are emitted for each contract in a batch...");
        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Contract 2";

        // Expect the events
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ContractAdded(address(mockContract1), "Contract 1");
        emit ContractAdded(address(mockContract2), "Contract 2");

        // Simulate admin action
        contractManager.addContracts(addresses, descriptions);
    }

    /// @notice Tests if adding contracts with mismatched input lengths reverts

    function testBatchAddRevertsOnMismatchedInputLengths() public {
        console.log("Testing if adding contracts in a batch with mismatched input lengths reverts...");

        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](3);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Contract 2";
        descriptions[2] = "Contract 3";

        // Simulate admin action
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("MismatchedInputLengths()"));
        contractManager.addContracts(addresses, descriptions);
    }
    /// @notice Tests if adding a batch with an invalid address reverts

    function testBatchAddRevertsOnInvalidAddress() public {
        console.log("Testing if adding contracts in a batch with an invalid address reverts...");
        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(0);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Invalid Address";

        // Simulate admin action
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        contractManager.addContracts(addresses, descriptions);
    }
    /// @notice Tests if adding duplicate contracts in a batch reverts

    function testBatchAddRevertsOnDuplicateContracts() public {
        console.log("Testing if adding duplicate contracts in a batch reverts...");
        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract1);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Duplicate Contract";

        // Simulate admin action
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("ContractAlreadyExists()"));
        contractManager.addContracts(addresses, descriptions);
    }
    /// @notice Tests the gas efficiency of batch addition compared to single additions

    function testBatchAddEfficiencyComparison() public {
        console.log("Testing gas efficiency of batch addition vs single additions...");

        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Contract 2";

        // Measure gas for single additions
        uint256 gasBeforeSingle = gasleft();
        vm.prank(admin);
        contractManager.addContract(addresses[0], descriptions[0]);
        uint256 gasAfterSingle1 = gasleft();

        // Remove the first contract after adding
        vm.prank(admin);
        contractManager.removeContract(addresses[0]);

        vm.prank(admin);
        contractManager.addContract(addresses[1], descriptions[1]);
        uint256 gasAfterSingle2 = gasleft();

        // Remove the second contract after adding
        vm.prank(admin);
        contractManager.removeContract(addresses[1]);

        uint256 gasUsedForSingleAdditions = (gasBeforeSingle - gasAfterSingle1) + (gasAfterSingle1 - gasAfterSingle2);

        // Measure gas for batch addition
        uint256 gasBeforeBatch = gasleft();
        vm.prank(admin);
        contractManager.addContracts(addresses, descriptions);
        uint256 gasAfterBatch = gasleft();

        uint256 gasUsedForBatchAddition = gasBeforeBatch - gasAfterBatch;

        console.log("Gas used for single additions:", gasUsedForSingleAdditions);
        console.log("Gas used for batch addition:", gasUsedForBatchAddition);

        // Assert that batch addition is more gas efficient
        assertTrue(gasUsedForBatchAddition < gasUsedForSingleAdditions, "Batch addition should be more gas efficient");
    }

    /// @notice Tests if adding a batch with an empty description reverts
    function testBatchAddRevertsOnEmptyDescription() public {
        console.log("Testing if adding a batch with an empty description reverts...");

        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "";

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("EmptyDescription()"));
        contractManager.addContracts(addresses, descriptions);
    }
    // @notice Tests if adding a batch with a description exceeding 256 characters reverts

    function testBatchAddRevertsOnOverLimitDescription() public {
        console.log("Testing if adding a batch with an over-limit description reverts...");
        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = new string(257); // Create a 257-character string
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("DescriptionTooLong(uint256,uint256)")),
                257, // Provided length
                256 // Max allowed length
            )
        );
        contractManager.addContracts(addresses, descriptions);
    }

    function testBatchAddRevertsWhenNonAdminCalls() public {
        console.log("Testing if a non-admin cannot add multiple contracts in a batch...");
        // Initialize dynamic arrays
        address[] memory addresses = new address[](2);
        addresses[0] = address(mockContract1);
        addresses[1] = address(mockContract2);

        string[] memory descriptions = new string[](2);
        descriptions[0] = "Contract 1";
        descriptions[1] = "Contract 2";

        // Simulate non-admin action
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")), user, keccak256("ADMIN_ROLE")
            )
        );
        contractManager.addContracts(addresses, descriptions);
    }

    // === Get Description ===

    /// @notice Tests if the correct description is returned for an existing contract
    function testGetDescriptionForExistingContract() public {
        console.log("Testing if the correct description is returned for an existing contract...");

        // Simulate the admin adding a contract with a description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Fetch the description of the added contract
        string memory description = contractManager.getDescription(address(mockContract1));

        // Assert that the fetched description matches the stored value
        assertEq(description, "Test Contract", "Description should match the stored value");
    }

    /// @notice Tests if querying the description of a non-existent contract reverts
    function testGetDescriptionRevertsForNonExistentContract() public {
        console.log("Testing if getting the description for a non-existent contract reverts...");

        // Attempt to fetch the description for a contract that hasn't been added
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.getDescription(address(mockContract1));
    }

    /// @notice Tests if querying the description of a removed contract reverts
    function testGetDescriptionRevertsForRemovedContract() public {
        console.log("Testing if getting the description for a removed contract reverts...");

        // Step 1: Admin adds a contract with a description
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");

        // Step 2: Admin removes the contract
        vm.prank(admin);
        contractManager.removeContract(address(mockContract1));

        // Step 3: Attempt to fetch the description of the removed contract
        vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
        contractManager.getDescription(address(mockContract1));
    }

    // === Role Management ===

    /// @notice Tests if an admin can grant the ADMIN_ROLE to a user
    function testAdminCanGrantAdminRole() public {
        console.log("Testing if an admin can grant ADMIN_ROLE to a user...");

        // Simulate the admin granting ADMIN_ROLE to the user
        vm.prank(admin);
        contractManager.grantRole(ADMIN_ROLE, user);

        // Assert that the user now has the ADMIN_ROLE
        assertTrue(
            contractManager.hasRole(ADMIN_ROLE, user), "User should have ADMIN_ROLE after it is granted by admin"
        );
    }

    /// @notice Tests if an admin can revoke the ADMIN_ROLE from a user
    function testAdminCanRevokeAdminRole() public {
        console.log("Testing if an admin can revoke ADMIN_ROLE from a user...");

        // Step 1: Admin grants ADMIN_ROLE to the user
        vm.prank(admin);
        contractManager.grantRole(ADMIN_ROLE, user);

        // Step 2: Admin revokes the ADMIN_ROLE from the user
        vm.prank(admin);
        contractManager.revokeRole(ADMIN_ROLE, user);

        // Assert that the user no longer has the ADMIN_ROLE
        assertFalse(
            contractManager.hasRole(ADMIN_ROLE, user), "User should not have ADMIN_ROLE after it is revoked by admin"
        );
    }

    /// @notice Tests if an admin can grant and revoke the ADMIN_ROLE for multiple users
    function testAdminCanGrantAndRevokeRolesForMultipleUsers() public {
        console.log("Testing if an admin can grant and revoke ADMIN_ROLE for multiple users...");

        // Step 1: Admin grants ADMIN_ROLE to multiple users
        vm.prank(admin);
        contractManager.grantRole(ADMIN_ROLE, user);
        contractManager.grantRole(ADMIN_ROLE, otherUser);

        // Assert that both users have the ADMIN_ROLE
        assertTrue(contractManager.hasRole(ADMIN_ROLE, user), "User should have ADMIN_ROLE after grant");
        assertTrue(contractManager.hasRole(ADMIN_ROLE, otherUser), "OtherUser should have ADMIN_ROLE after grant");

        // Step 2: Admin revokes ADMIN_ROLE from both users
        vm.prank(admin);
        contractManager.revokeRole(ADMIN_ROLE, user);
        contractManager.revokeRole(ADMIN_ROLE, otherUser);

        // Assert that neither user has the ADMIN_ROLE anymore
        assertFalse(contractManager.hasRole(ADMIN_ROLE, user), "User should not have ADMIN_ROLE after revoke");
        assertFalse(contractManager.hasRole(ADMIN_ROLE, otherUser), "OtherUser should not have ADMIN_ROLE after revoke");
    }

    /// @notice Tests if a non-admin cannot grant the ADMIN_ROLE
    function testNonAdminCannotGrantAdminRole() public {
        console.log("Testing if a non-admin cannot grant ADMIN_ROLE...");

        // Simulate a non-admin attempting to grant ADMIN_ROLE to another user
        vm.startPrank(user); // Persist `user` as the caller for subsequent actions
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                user, // The unauthorized user
                contractManager.DEFAULT_ADMIN_ROLE() // Required role for granting ADMIN_ROLE
            )
        );
        contractManager.grantRole(ADMIN_ROLE, otherUser);

        // Stop impersonating the non-admin user
        vm.stopPrank();
    }

    /// @notice Tests if a non-admin cannot revoke the ADMIN_ROLE
    function testNonAdminCannotRevokeAdminRole() public {
        console.log("Testing if a non-admin cannot revoke ADMIN_ROLE...");

        // Step 1: Admin grants ADMIN_ROLE to the user
        vm.prank(admin);
        contractManager.grantRole(ADMIN_ROLE, user);

        // Step 2: Simulate a non-admin user attempting to revoke their own ADMIN_ROLE
        vm.startPrank(user); // Persist `user` as the caller for subsequent actions
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                user, // The unauthorized user
                contractManager.DEFAULT_ADMIN_ROLE() // Required role for revoking ADMIN_ROLE
            )
        );
        contractManager.revokeRole(ADMIN_ROLE, user);

        // Stop impersonating the non-admin user
        vm.stopPrank();
    }
}
