const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniV3PDNVault", function () {
  it("Should transfer the funds to the owner", async function () {
    // const Vault = await ethers.getContractFactory("UniV3PDNVault");
    // const vault = await Vault.deploy();
    const btc = new ethers.Contract(
      "0x68f180fcCe6836688e9084f035309E29Bf0A2095",
      ["function balanceOf(address) view returns (uint256)"],
      ethers.provider
    );
    console.log(
      "btc balance: ",
      (
        await btc.balanceOf("0x73b14a78a0d396c521f954532d43fd5ffe385216")
      ).toString()
    );
  });
});
