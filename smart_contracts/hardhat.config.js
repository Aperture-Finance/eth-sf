const { ETH_PRV_KEY_1 } = require("./constants");

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("hardhat-abi-exporter");
require("hardhat-contract-sizer");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        // details: {
        //   yul: true,
        // },
      },
      // viaIR: true,
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      forking: {
        url: "https://opt-mainnet.g.alchemy.com/v2/RWdtPbSEoTigtP_JqflHSnbIY8XsbRF4",
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  abiExporter: {
    path: "./data/abi",
    runOnCompile: true,
    clear: true,
    flat: false,
    spacing: 2,
    pretty: true,
  },
};
