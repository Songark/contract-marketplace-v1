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
    treasury, 
    gameWallet,
    TokenTypes_membershipNFT,
    TokenTypes_customNFT,
    TokenTypes_erc20Token
}