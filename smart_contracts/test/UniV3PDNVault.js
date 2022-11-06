const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { expect } = require("chai");
const {
  ETH_USDC_POOL_ADDR,
  WETH_ADDR,
  USDC_ADDR,
  BANK_ADDR,
  SPELL_ADDR,
  ETH_PRV_KEY_1,
  OPTIMAL_SWAP_ADDR,
} = require("../constants");
const fs = require("fs");

const BANK_ABI = JSON.parse(
  fs.readFileSync(
    "data/abi/contracts/interfaces/homorav2/banks/IBankOP.sol/IBankOP.json"
  )
);
const homoraBank = new ethers.Contract(BANK_ADDR, BANK_ABI, ethers.provider);
const ERC20_ABI = JSON.parse(
  fs.readFileSync(
    "data/abi/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json"
  )
);
const USDC_DECIMALS = BigNumber.from(10).pow(6);

describe("UniV3PDNVault", function () {
  let wallet;
  let vault;

  beforeEach("Setup before each test", async function () {
    wallet = await ethers.getImpersonatedSigner(
      "0xa3f45e619cE3AAe2Fa5f8244439a66B203b78bCc"
    );
    const homoraBankGovernor = await homoraBank.governor();
    console.log(`Governor: ${homoraBankGovernor}`);
    const governorSigner = await ethers.getImpersonatedSigner(
      homoraBankGovernor
    );

    await wallet.sendTransaction({
      to: homoraBankGovernor,
      value: ethers.utils.parseEther("1"),
    });

    const contractFactory = await ethers.getContractFactory(
      "UniV3PDNVault",
      wallet
    );
    vault = await contractFactory.deploy(
      SPELL_ADDR,
      USDC_ADDR,
      WETH_ADDR,
      ETH_USDC_POOL_ADDR,
      OPTIMAL_SWAP_ADDR
    );
    await vault.deployed();
    console.log(`Vault deployed to address ${vault.address}.`);
    vault = vault.connect(wallet);
    await vault.setConfig(30000, 100);

    const bankStatus = await homoraBank.bankStatus();
    console.log(`Bank status: ${bankStatus}`);
    expect(await homoraBank.allowBorrowStatus()).to.be.true;
    expect(await homoraBank.whitelistedTokens(WETH_ADDR)).to.be.true;
    expect(await homoraBank.whitelistedTokens(USDC_ADDR)).to.be.true;
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

    const CL1 = USDC_DECIMALS.mul(100000);
    const CL2 = ethers.utils.parseEther("100000");
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
  });

  it("open position", async function () {
    // Approve token.
    const USDC = new ethers.Contract(USDC_ADDR, ERC20_ABI, wallet);
    await USDC.approve(vault.address, USDC_DECIMALS.mul(USDC_DECIMALS));

    // Open position.
    await vault.connect(wallet).deposit(13000, USDC_DECIMALS.mul(10000));

    const [oracle, collateralETHValue, borrowETHValue, debtRatio, debtAmounts] =
      await Promise.all([
        vault.oracle(),
        vault.getCollateralETHValue(wallet.address),
        vault.getBorrowETHValue(wallet.address),
        vault.getDebtRatio(wallet.address),
        vault.getDebtAmounts(wallet.address),
      ]);
    console.log(`oracle: ${oracle}`);
    console.log(`collateralETHValue: ${collateralETHValue}`);
    console.log(`borrowETHValue: ${borrowETHValue}`);
    console.log(`debtRatio: ${debtRatio}`);
    console.log(`debtAmounts: ${debtAmounts}`);

    const [
      uniV3PositionManagerId,
      pool,
      bene,
      token0,
      token1,
      fee,
      liquidity,
      tickLower,
      tickUpper,
    ] = await vault.getUniV3PositionInfo(wallet.address);
    console.log(`uniV3PositionManagerId: ${uniV3PositionManagerId}`);
    console.log(`pool: ${pool}`);
    console.log(`bene: ${bene}`);
    console.log(`token0: ${token0}`);
    console.log(`token1: ${token1}`);
    console.log(`fee: ${fee}`);
    console.log(`liquidity: ${liquidity}`);
    console.log(`tickLower: ${tickLower}`);
    console.log(`tickUpper: ${tickUpper}`);
  });
});
