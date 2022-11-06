module.exports = {
  ETH_PRV_KEY_1:
    "0x53f446e52f3cb33084b0c31baee7542392844776ff593f444a480b29ed964ff8",
  USDC_ETH_POOL_ADDR: "0x85149247691df622eaf1a8bd0cafd40bc45154a9",
  POOL_ABI: [
    "function slot0() view returns (uint160, int24, uint16, uint16, uint16, uint8, bool)",
    "function tickSpacing() view returns (int24)",
    "function token0() view returns (address)",
    "function token1() view returns (address)",
  ],
  BANK_ABI: [
    "function execute(uint256,address,bytes memory) returns (uint256)",
    "function exec() returns (address)",
    "function governor() view returns (address)",
    "function setAllowContractCalls(bool)",
    "function allowContractCalls() view returns (bool)",
    "function setWhitelistContractWithTxOrigin(address[],address[],bool[])",
    "function setWhitelistUsers(address[],bool[])",
    "function setCreditLimits(tuple(address,address,uint256,address)[])",
    "function bankStatus() view returns (uint256)",
    "function allowBorrowStatus() view returns (bool)",
    "function setExec(address)",
    "function exec() view returns (address)",
  ],
  OPTIMAL_SWAP_ABI: [
    "function getOptimalSwapAmt(address, uint256, uint256, int24, int24) view returns (uint256, uint256, bool)",
  ],
  ERC20_ABI: ["function approve (address, uint256) returns(bool)"],
  WETH_ADDR: "0x4200000000000000000000000000000000000006",
  USDC_ADDR: "0x7f5c764cbc14f9669b88837ca1490cca17c31607",
  BANK_ADDR: "0xFFa51a5EC855f8e38Dd867Ba503c454d8BBC5aB9",
  SPELL_ADDR: "0xBF956ECDbd08d9aeA6Ef0Cdd305d054859EBc130",
  OPTIMAL_SWAP_ADDR: "0xC781Cf972AB97601efeCFfA53202A410f52FEF92",
};
