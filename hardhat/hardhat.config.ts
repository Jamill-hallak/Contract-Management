import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.22", // Use the latest stable version or one compatible with your contracts
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  }
  
};

export default config;
