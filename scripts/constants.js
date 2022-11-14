const nftTokenCount = 20;
const pbrtTokenBalance = 10000;

const nftBuyers = [
    "0xe6fDef5b2C067ebEB01DdEe75c270c61Bd21b7B8",
    "0xF0d096D33559cDc5f527435b82073c108D6c3107"
];

const nftSellers = [
    "0xe6fDef5b2C067ebEB01DdEe75c270c61Bd21b7B8",
    "0xF0d096D33559cDc5f527435b82073c108D6c3107"
];

const usdcAddresses = [
    "0xe6b8a5cf854791412c1f6efc7caf629f5df1c747",   // mumbai
    "0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557"    // goerli
];

const treasury = "0xF0d096D33559cDc5f527435b82073c108D6c3107";
const gameWallet = "0xd5439F21fd46f2eA74563443626f0246E268983f";
const gamePlayV2 = "0x8004422baEb59146d548fb0C238848CCe4B1B31F";
const TokenTypes_membershipNFT = 0;
const TokenTypes_customNFT = 1;
const TokenTypes_erc20Token = 2;
module.exports = {
    nftTokenCount, pbrtTokenBalance, 
    nftBuyers, 
    nftSellers, 
    usdcAddresses,
    treasury, 
    gameWallet,
    gamePlayV2,
    TokenTypes_membershipNFT,
    TokenTypes_customNFT,
    TokenTypes_erc20Token
}