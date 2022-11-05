const { ETH_PRV_KEY_1 } = require("./constants");

require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      forking: {
        url: "https://mainnet.optimism.io",
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
