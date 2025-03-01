import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";

import "@solarity/hardhat-zkit";
import "@solarity/chai-zkit";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  zkit: {
    compilerVersion: "2.1.9",
    circuitsDir: "circuits",
    compilationSettings: {
      artifactsDir: "zkit/artifacts",
      onlyFiles: [],
      skipFiles: [],
      c: false,
      json: false,
      optimization: "O1",
    },
    setupSettings: {
      contributionSettings: {
        provingSystem: "groth16", // or "plonk"
        contributions: 2,
      },
      onlyFiles: [],
      skipFiles: [],
      ptauDir: undefined,
      ptauDownload: true,
    },
    verifiersSettings: {
      verifiersDir: "contracts/verifiers",
      verifiersType: "sol", // or "vy"
    },
    typesDir: "generated-types/zkit",
    quiet: false,
  },
};

export default config;
