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

const provider = ethers.provider;

describe("UniV3PDNVault", function () {
  it("open position", async function () {
    // const Vault = await ethers.getContractFactory("UniV3PDNVault");
    // const vault = await Vault.deploy();

    const multiplier = 100;
    const bank = new ethers.Contract(BANK_ADDR, BANK_ABI, provider);

    // const wallet = new ethers.Wallet(ETH_PRV_KEY_1, provider);
    const wallet = await ethers.getImpersonatedSigner(
      "0xa3f45e619cE3AAe2Fa5f8244439a66B203b78bCc"
    );
    // Approve token.
    const USDC = new ethers.Contract(USDC_ADDR, ERC20_ABI, wallet);
    await USDC.approve(bank.address, BigNumber.from(10).pow(18));

    const pool = new ethers.Contract(USDC_ETH_POOL_ADDR, POOL_ABI, provider);

    console.log(
      `token0: ${await pool.token0()}, token1: ${await pool.token1()}`
    );
    const [, tick, , , , ,] = await pool.slot0();
    console.log(tick);
    const tickSpacing = await pool.tickSpacing();
    console.log("tick spacing: ", tickSpacing);

    const tickLower = tick - multiplier * tickSpacing;
    const tickUpper = tick + multiplier * tickSpacing;
    const userSupplyTokenA = BigNumber.from(10).pow(18).mul(0);
    const userSupplyTokenB = BigNumber.from(10).pow(6).mul(1000);
    const optimalSwap = new ethers.Contract(
      OPTIMAL_SWAP_ADDR,
      OPTIMAL_SWAP_ABI,
      provider
    );
    const [amtSwap, amtOut, isZeroForOne] = await optimalSwap.getOptimalSwapAmt(
      pool.address,
      userSupplyTokenA.add(userSupplyTokenA),
      userSupplyTokenB.add(userSupplyTokenB),
      tickLower,
      tickUpper
    );

    console.log(
      `amtSwap: ${amtSwap.toString()}, amtOut: ${amtOut.toString()}, isZeroForOne: ${isZeroForOne}`
    );

    const openParams = [
      WETH_ADDR,
      USDC_ADDR,
      500, // fee
      tickLower,
      tickUpper,
      userSupplyTokenA,
      userSupplyTokenB,
      userSupplyTokenA,
      userSupplyTokenB,
      0,
      0,
      amtSwap,
      amtOut,
      isZeroForOne,
      BigNumber.from(
        "115792089237316195423570985008687907853269984665640564039457584007913129639935"
      ),
    ];

    console.log("openParams:", openParams);

    const posId = 0;
    const encodedOpenData = ethers.utils.defaultAbiCoder.encode(
      [
        "address",
        "address",
        "uint24",
        "int24",
        "int24",
        "uint",
        "uint",
        "uint",
        "uint",
        "uint",
        "uint",
        "uint",
        "uint",
        "bool",
        "uint",
      ],
      openParams
    );
    await bank.connect(wallet).execute(posId, SPELL_ADDR, encodedOpenData);
  });
});
