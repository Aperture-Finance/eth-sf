const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { expect } = require("chai");
const {
  POOL_ABI,
  USDC_ETH_POOL_ADDR,
  WETH_ADDR,
  USDC_ADDR,
  BANK_ADDR,
  SPELL_ADDR,
  ETH_PRV_KEY_1,
  OPTIMAL_SWAP_ADDR,
  OPTIMAL_SWAP_ABI,
  ERC20_ABI,
} = require("../constants");
const fs = require("fs");

const BANK_ABI = JSON.parse(
  fs.readFileSync(
    "data/abi/contracts/interfaces/homorav2/banks/IBankOP.sol/IBankOP.json"
  )
);

describe("UniV3PDNVault", function () {
  it("open position", async function () {
    const wallet = await ethers.getImpersonatedSigner(
      "0xa3f45e619cE3AAe2Fa5f8244439a66B203b78bCc"
    );

    const homoraBank = new ethers.Contract(
      BANK_ADDR,
      BANK_ABI,
      ethers.provider
    );
    const homoraBankGovernor = await homoraBank.governor();
    console.log("governor: ", homoraBankGovernor);
    const governorSigner = await ethers.getImpersonatedSigner(
      homoraBankGovernor
    );

    await wallet.sendTransaction({
      to: homoraBankGovernor,
      value: ethers.utils.parseEther("100"),
    });

    const executor = await homoraBank.connect(governorSigner).exec();
    console.log("exec address", executor);
    await wallet.sendTransaction({
      value: BigNumber.from(1).mul(BigNumber.from(10).pow(18)),
      to: executor,
      gasPrice: 50000000000,
      gasLimit: 2000000,
    });
    const executorSigner = await ethers.getImpersonatedSigner(executor);
    await homoraBank.connect(executorSigner).setAllowContractCalls(true);
    console.log("set allow contract calls");
    console.log(
      "allowContractCallsResult: ",
      await homoraBank.allowContractCalls()
    );
    console.log("allowBorrowStatus: ", await homoraBank.allowBorrowStatus());
    console.log(
      "whitelistedTokens: USDC",
      await homoraBank.whitelistedTokens(USDC_ADDR)
    );
    console.log(
      "whitelistedTokens: WETH",
      await homoraBank.whitelistedTokens(WETH_ADDR)
    );

    const Vault = await ethers.getContractFactory("UniV3PDNVault");
    const vault = await Vault.deploy(
      SPELL_ADDR,
      USDC_ADDR,
      WETH_ADDR,
      USDC_ETH_POOL_ADDR,
      OPTIMAL_SWAP_ADDR
    );
    await vault.deployed();
    console.log(`Vault deployed to address ${vault.address}.`);
    await vault.setConfig(30000, 0);

    await homoraBank
      .connect(governorSigner)
      .setWhitelistUsers([vault.address], [true]);
    console.log("setWhitelistUsers finished.");
    expect(await homoraBank.whitelistedUsers(vault.address)).to.be.true;
    await homoraBank
      .connect(governorSigner)
      .setWhitelistContractWithTxOrigin(
        [vault.address],
        [wallet.address],
        [true]
      );
    console.log("setWhitelistContractWithTxOrigin finished.");
    expect(
      await homoraBank.whitelistedContractWithTxOrigin(
        vault.address,
        wallet.address
      )
    ).to.be.true;

    const CL1 = BigNumber.from(10).pow(6).mul(100000);
    const CL2 = BigNumber.from(10).pow(18).mul(100000);
    await homoraBank.connect(governorSigner).setCreditLimits([
      [vault.address, USDC_ADDR, CL1, wallet.address],
      [vault.address, WETH_ADDR, CL2, wallet.address],
    ]);
    console.log("Credit limits set.");
    expect(
      await homoraBank.whitelistedUserCreditLimits(vault.address, USDC_ADDR)
    ).to.be.eq(CL1);
    expect(
      await homoraBank.whitelistedUserCreditLimits(vault.address, WETH_ADDR)
    ).to.be.eq(CL2);

    const bankStatus = await homoraBank.bankStatus();
    console.log("Bank status: ", bankStatus);

    // Approve token.
    const USDC = new ethers.Contract(USDC_ADDR, ERC20_ABI, wallet);
    await USDC.approve(vault.address, BigNumber.from(10).pow(12));

    // Open position.
    await vault
      .connect(wallet)
      .deposit(13000, BigNumber.from(10).pow(6).mul(100));
  });
});
