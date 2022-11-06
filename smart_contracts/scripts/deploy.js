// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");
const hre = require("hardhat");
const {
  SPELL_ADDR,
  USDC_ADDR,
  WETH_ADDR,
  USDC_ETH_POOL_ADDR,
  OPTIMAL_SWAP_ADDR,
  BANK_ADDR,
  BANK_ABI,
} = require("../constants");

const axios = require("axios");

const TENDERLY_USER = "Aperture";
const TENDERLY_PROJECT = "project";
const TENDERLY_ACCESS_KEY = "JjDBDY4pIpZPyZNDQtFKRBmNLSYDH35d";
const SIMULATE_API = `https://api.tenderly.co/api/v1/account/${TENDERLY_USER}/project/${TENDERLY_PROJECT}/fork/3285a8b9-7dc8-4e68-bfe9-bd9f9a76358c/simulate`;
const opts = {
  headers: {
    "X-Access-Key": TENDERLY_ACCESS_KEY,
  },
};

const tenderlyURL =
  "https://rpc.tenderly.co/fork/3285a8b9-7dc8-4e68-bfe9-bd9f9a76358c";
const tenderlyProvider = new ethers.providers.JsonRpcProvider(tenderlyURL);

async function main() {
  const signer = tenderlyProvider.getSigner();
  const Vault = await ethers.getContractFactory("UniV3PDNVault", signer);
  // const vault = await Vault.deploy(
  //   SPELL_ADDR,
  //   USDC_ADDR,
  //   WETH_ADDR,
  //   USDC_ETH_POOL_ADDR,
  //   OPTIMAL_SWAP_ADDR
  // );
  // await vault.deployed();
  // console.log(`Vault deployed to address ${vault.address}`);
  // await vault.setConfig(30000, 0);

  const vaultAddr = "0xcd9002c47348c54b1c044e30e449cdae44124139";
  const vaultContract = Vault.attach(vaultAddr);

  const homoraBank = new ethers.Contract(BANK_ADDR, BANK_ABI, signer);
  const homoraBankGovernor = await homoraBank.governor();
  console.log("governor: ", homoraBankGovernor);

  const governorSigner = await ethers.getImpersonatedSigner(homoraBankGovernor);

  let TX_DATA = await homoraBank
    .connect(governorSigner)
    .populateTransaction["setWhitelistUsers"]([vaultAddr], [true]);
  let transaction = {
    network_id: "10",
    from: homoraBankGovernor,
    input: TX_DATA.data,
    to: BANK_ADDR,
    // tenderly specific
    save: true,
  };
  try {
    const resp = await axios.post(SIMULATE_API, transaction, opts);
    console.log(resp.data);
  } catch (error) {
    console.dir(error, { depth: null });
  }
  console.log("setWhitelistUsers finished.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
