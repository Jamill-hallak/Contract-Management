// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ContractManager} from "../src/ContractManager.sol";
import {MockContract} from "../src/MockContract.sol";
import {IContractManager} from "../src/IContractManager.sol";

contract ContractManagerTest is Test {
    ContractManager private contractManager;
    MockContract private mockContract1;
    MockContract private mockContract2;
    address private deployer;
    address private admin;
    address private user;
    address private otherUser;
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bool consoleloggedSetup;
    event ContractAdded(address indexed contractAddress, string description);
    event ContractUpdated(address indexed contractAddress, string newDescription);
    event ContractRemoved(address indexed contractAddress);



// function logSetup() internal {
//         if (!consoleloggedSetup) {
//             console.log("Setting up the test environment...");
//             console.log("Deploying ContractManager and assigning roles...");
//             console.log("Deploying Mock Contracts...");
//             consoleloggedSetup = true;
//         }
//     }
    function setUp() public {
            
       
        deployer = address(this);
        admin = makeAddr("admin");
        user = makeAddr("user");
        otherUser = makeAddr("otherUser");

        // Deploy ContractManager and assign roles
        // Deploy mock contracts

         contractManager = new ContractManager(admin);
         mockContract1 = new MockContract();
         mockContract2 = new MockContract();
        

        vm.prank(deployer);
        // Assign admin role
    contractManager.grantRole(contractManager.DEFAULT_ADMIN_ROLE(), admin);

         
        
    }

    // === Deployment Tests  ===
    function testDefaultAdminRoleAssigned() view public {
        console.log("Testing if DEFAULT_ADMIN_ROLE is assigned to the deployer...");
        bytes32 defaultAdminRole = contractManager.DEFAULT_ADMIN_ROLE();
        assertTrue(contractManager.hasRole(defaultAdminRole, deployer), "Deployer should have DEFAULT_ADMIN_ROLE");
    }

    function testAdminRoleAssigned() view public {
        console.log("Testing if ADMIN_ROLE is assigned to the admin...");
        assertTrue(contractManager.hasRole(ADMIN_ROLE, admin), "Admin should have ADMIN_ROLE");
    }

    function testNonExistentRoleCheck() view public {
        console.log("Testing if a non-existent role is not assigned...");
        assertFalse(contractManager.hasRole(keccak256("UNKNOWN_ROLE"), admin), "Unknown role should not be assigned to admin");
    }

    // === Interface Compliance Tests  ===
    function testSupportsIContractManager() view public {
        console.log("Testing if ContractManager supports IContractManager interface...");
        bytes4 interfaceId = type(IContractManager).interfaceId;
        assertTrue(contractManager.supportsInterface(interfaceId), "ContractManager should support IContractManager interface");
    }

    function testSupportsAccessControl() view public {
        console.log("Testing if ContractManager supports AccessControl interface...");
        bytes4 accessControlInterfaceId = 0x7965db0b;
        assertTrue(contractManager.supportsInterface(accessControlInterfaceId), "ContractManager should support AccessControl interface");
    }

    function testDoesNotSupportInvalidInterface() view public {
        console.log("Testing if ContractManager does not support an invalid interface...");
        bytes4 invalidInterfaceId = 0xffffffff;
        assertFalse(contractManager.supportsInterface(invalidInterfaceId), "ContractManager should not support invalid interface");
    }

    function testMultipleInterfaceIds()view public {
        console.log("Testing multiple interface IDs support (AccessControl,IContractManager)...");
        bytes4 accessControlInterfaceId = 0x7965db0b;
        bytes4 contractManagerInterfaceId = type(IContractManager).interfaceId;
        assertTrue(contractManager.supportsInterface(accessControlInterfaceId), "Should support AccessControl interface");
        assertTrue(contractManager.supportsInterface(contractManagerInterfaceId), "Should support IContractManager interface");
    }

    // === Adding Contracts ===
    function testAdminCanAddContract()  public {
        console.log("Testing if an admin can add a contract...");
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");
        string memory description = contractManager.getDescription(address(mockContract1));
        assertEq(description, "Test Contract", "Contract description should match");
    }

    function testEmitContractAddedEvent()   public {
        console.log("Testing if ContractAdded event is emitted when adding a contract...");
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ContractAdded(address(mockContract1), "Test Contract");
        contractManager.addContract(address(mockContract1), "Test Contract");
    }

    function testCannotAddZeroAddress() public {
        console.log("Testing if adding a zero address reverts...");
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        contractManager.addContract(address(0), "Invalid Contract");
    }

    function testCannotAddAlreadyExistingContract()  public {
        console.log("Testing if adding an already existing contract reverts...");
        vm.prank(admin);
        contractManager.addContract(address(mockContract1), "Test Contract");
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("ContractAlreadyExists()"));
        contractManager.addContract(address(mockContract1), "Duplicate Contract");
    }

    function testCannotAddNonContractAddress()  public {
        console.log("Testing if adding a non-contract address reverts...");
        address randomAddress = makeAddr("random");
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        contractManager.addContract(randomAddress, "Invalid Contract");
    }

    function testNonAdminCannotAddContract()  public {
        console.log("Testing if a non-admin cannot add a contract...");
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
            bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
            user,
            keccak256("ADMIN_ROLE")
        ));
        contractManager.addContract(address(mockContract1), "Unauthorized Contract");
    }
    function testReAddContractAfterRemoval() public {
    console.log("Testing if a contract can be re-added after removal...");

    // Step 1: Admin adds and then removes a contract
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Test Contract");
    vm.prank(admin);
    contractManager.removeContract(address(mockContract1));

    // Step 2: Attempt to re-add the same contract
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Re-Added Contract");

    // Step 3: Verify that the new description is stored and the state has been reset
    string memory newDescription = contractManager.getDescription(address(mockContract1));
    assertEq(newDescription, "Re-Added Contract", "State should not be clean after re-adding the contract");
}


    // === Removing Contracts ===
function testAdminCanRemoveContract() public {
    console.log("Testing if an admin can remove a contract...");
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Test Contract");

    vm.prank(admin);
    contractManager.removeContract(address(mockContract1));

    vm.prank(admin);
    vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
    contractManager.getDescription(address(mockContract1));
}

function testEmitContractRemovedEvent() public {
    console.log("Testing if ContractRemoved event is emitted when removing a contract...");
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Test Contract");

    vm.prank(admin);
    vm.expectEmit(true, true, true, true);
    emit ContractRemoved(address(mockContract1));
    contractManager.removeContract(address(mockContract1));
}

function testCannotRemoveNonExistentContract() public {
    console.log("Testing if removing a non-existent contract reverts...");
    vm.prank(admin);
    vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
    contractManager.removeContract(address(mockContract1));
}

function testCannotRemoveZeroAddress() public {
    console.log("Testing if removing a zero address reverts...");
    vm.prank(admin);
    vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
    contractManager.removeContract(address(0));
}

function testNonAdminCannotRemoveContract() public {
    console.log("Testing if a non-admin cannot remove a contract...");
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Test Contract");

    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(
        bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
        user,
        keccak256("ADMIN_ROLE")
    ));
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
function testAdminCanUpdateDescription() public {
    console.log("Testing if an admin can update a contract description...");
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Initial Description");

    vm.prank(admin);
    contractManager.updateDescription(address(mockContract1), "Updated Description");

    string memory updatedDescription = contractManager.getDescription(address(mockContract1));
    assertEq(updatedDescription, "Updated Description", "Contract description should be updated");
}

function testEmitContractUpdatedEvent() public {
    console.log("Testing if ContractUpdated event is emitted when updating a description...");
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Initial Description");

    vm.prank(admin);
    vm.expectEmit(true, true, true, true);
    emit ContractUpdated(address(mockContract1), "Updated Description");
    contractManager.updateDescription(address(mockContract1), "Updated Description");
}

function testCannotUpdateDescriptionForNonExistentContract() public {
    console.log("Testing if updating a non-existent contract reverts...");
    vm.prank(admin);
    vm.expectRevert(abi.encodeWithSignature("ContractDoesNotExist()"));
    contractManager.updateDescription(address(mockContract1), "Updated Description");
}

function testNonAdminCannotUpdateDescription() public {
    console.log("Testing if a non-admin cannot update a contract description...");
    vm.prank(admin);
    contractManager.addContract(address(mockContract1), "Initial Description");

    vm.prank(user);
    vm.expectRevert(abi.encodeWithSelector(
        bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
        user,
        keccak256("ADMIN_ROLE")
    ));
    contractManager.updateDescription(address(mockContract1), "Unauthorized Update");
}

// === Role Management ===
function testAdminCanGrantAdminRole() public {
    console.log("Testing if an admin can grant ADMIN_ROLE to a user...");
    vm.prank(admin);
    contractManager.grantRole(ADMIN_ROLE, user);
    assertTrue(contractManager.hasRole(ADMIN_ROLE, user), "User should have ADMIN_ROLE after it is granted by admin");
}
function testAdminCanRevokeAdminRole() public {
    console.log("Testing if an admin can revoke ADMIN_ROLE from a user...");
    vm.prank(admin);
    contractManager.grantRole(ADMIN_ROLE, user);

    vm.prank(admin);
    contractManager.revokeRole(ADMIN_ROLE, user);

    assertFalse(contractManager.hasRole(ADMIN_ROLE, user), "User should not have ADMIN_ROLE after it is revoked by admin");
}
function testAdminCanGrantAndRevokeRolesForMultipleUsers() public {
    console.log("Testing if an admin can grant and revoke ADMIN_ROLE for multiple users...");
    vm.prank(admin);
    contractManager.grantRole(ADMIN_ROLE, user);
    contractManager.grantRole(ADMIN_ROLE, otherUser);

    assertTrue(contractManager.hasRole(ADMIN_ROLE, user), "User should have ADMIN_ROLE after grant");
    assertTrue(contractManager.hasRole(ADMIN_ROLE, otherUser), "OtherUser should have ADMIN_ROLE after grant");

    vm.prank(admin);
    contractManager.revokeRole(ADMIN_ROLE, user);
    contractManager.revokeRole(ADMIN_ROLE, otherUser);

    assertFalse(contractManager.hasRole(ADMIN_ROLE, user), "User should not have ADMIN_ROLE after revoke");
    assertFalse(contractManager.hasRole(ADMIN_ROLE, otherUser), "OtherUser should not have ADMIN_ROLE after revoke");
}


function testNonAdminCannotGrantAdminRole() public {
    console.log("Testing if a non-admin cannot grant ADMIN_ROLE...");
    vm.startPrank(user); // Persist `user` as the caller for subsequent calls
    vm.expectRevert(abi.encodeWithSelector(
        bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
        user,
        contractManager.DEFAULT_ADMIN_ROLE() // Correct role requirement
    ));
    contractManager.grantRole(ADMIN_ROLE, otherUser);
    vm.stopPrank(); // Stop the prank to restore the original sender
}

function testNonAdminCannotRevokeAdminRole() public {
    console.log("Testing if a non-admin cannot revoke ADMIN_ROLE...");

    // Step 1: Grant ADMIN_ROLE to `user` by `admin`
    vm.prank(admin);
    contractManager.grantRole(ADMIN_ROLE, user);

    // Step 2: Simulate `user` attempting to revoke their own ADMIN_ROLE
    vm.startPrank(user); // Persist `user` as msg.sender for subsequent calls
    vm.expectRevert(abi.encodeWithSelector(
        bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
        user, // Expected sender
        contractManager.DEFAULT_ADMIN_ROLE() // Required role for revoking
    ));
    contractManager.revokeRole(ADMIN_ROLE, user);
    vm.stopPrank(); // Restore the original sender
}




}
