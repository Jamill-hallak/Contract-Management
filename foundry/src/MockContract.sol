// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MockContract
///@author Jamil Hallack
/// @notice A simple mock contract used for testing purposes
/// @dev This contract is designed to simulate basic contract behavior for unit testing
contract MockContract {
    function test() public pure returns (string memory) {
        return "Mock Contract";
    }
}
