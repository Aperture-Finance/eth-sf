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
        runs: 2 ** 32 - 1,
        details: {
          yul: true,
        },
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      forking: {
        url: "https://opt-mainnet.g.alchemy.com/v2/RWdtPbSEoTigtP_JqflHSnbIY8XsbRF4",
      },
    },
    tenderly: {
      url: "https://rpc.tenderly.co/fork/3285a8b9-7dc8-4e68-bfe9-bd9f9a76358c",
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
