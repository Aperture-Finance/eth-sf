const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const {
  POOL_ABI,
  USDC_ETH_POOL_ADDR,
  WETH_ADDR,
  USDC_ADDR,
  BANK_ADDR,
  BANK_ABI,
  SPELL_ADDR,
  ETH_PRV_KEY_1,
  OPTIMAL_SWAP_ADDR,
  OPTIMAL_SWAP_ABI,
  ERC20_ABI,
} = require("../constants");

describe("UniV3PDNVault", function () {
  it("open position", async function () {
    const wallet = await ethers.getImpersonatedSigner(
      "0xa3f45e619cE3AAe2Fa5f8244439a66B203b78bCc"
    );

    const homoraBank = new ethers.Contract(BANK_ADDR, BANK_ABI, ethers.provider);
    const homoraBankGovernor = await homoraBank.governor();
    console.log("governor: ", homoraBankGovernor);
    const governorSigner = await ethers.getImpersonatedSigner(homoraBankGovernor);

    await wallet.sendTransaction({
      to: homoraBankGovernor,
      value: ethers.utils.parseEther("100"),
    });

    // await homoraBank.connect(wallet).setAllowContractCalls(true);
    // console.log("set allow contract calls");
    const allowContractCallsResult = await homoraBank.allowContractCalls();
    console.log("allowContractCallsResult: ", allowContractCallsResult);

    const Vault = await ethers.getContractFactory("UniV3PDNVault");
    const vault = await Vault.deploy(SPELL_ADDR, USDC_ADDR, WETH_ADDR, USDC_ETH_POOL_ADDR, OPTIMAL_SWAP_ADDR);
    await vault.deployed();
    console.log(`Vault deployed to address ${vault.address}.`);
    await vault.setConfig(30000, 0);

    await homoraBank.connect(governorSigner).setWhitelistUsers([vault.address], [true]);
    console.log("Whitelisted vault.");

    await homoraBank.connect(governorSigner).setCreditLimits([
      [vault.address, USDC_ADDR, BigNumber.from(10).pow(6).mul(100000), ethers.constants.AddressZero],
      [vault.address, WETH_ADDR, BigNumber.from(10).pow(18).mul(100000), ethers.constants.AddressZero]
    ]);
    console.log("Credit limits set.");

    const bankStatus = await homoraBank.bankStatus();
    console.log("Bank status: ", bankStatus);

    // Approve token.
    const USDC = new ethers.Contract(USDC_ADDR, ERC20_ABI, wallet);
    await USDC.approve(vault.address, BigNumber.from(10).pow(12));

    // Open position.
    await vault.connect(wallet).deposit(13000, BigNumber.from(10).pow(6).mul(1000));
  });
});
