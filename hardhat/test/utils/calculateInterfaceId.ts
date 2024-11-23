import { ethers } from "hardhat";

/**
 * Calculates the EIP-165 interface ID for a given list of function signatures.
 * @param functions Array of function signatures (e.g., "functionName(paramType1,paramType2)").
 * @returns The EIP-165 interface ID as a string (e.g., "0x12345678").
 */
export async function calculateInterfaceId(functions: string[]): Promise<string> {
    const functionSelectors = functions.map((fn) =>
      ethers.id(fn).substring(0, 10) // Get the first 4 bytes of the keccak256 hash
    );
  
    const interfaceId = functionSelectors
      .map((selector) => BigInt(selector)) // Convert hex string to BigInt for safe XOR
      .reduce((acc, cur) => acc ^ cur, BigInt(0)); // XOR all selectors using BigInt
  
    return "0x" + interfaceId.toString(16).padStart(8, "0"); // Format as hex string
  }