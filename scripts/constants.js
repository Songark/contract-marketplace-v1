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

const pbrtAddresses = [
    "",   // mumbai
    "0x5A7ba86C5CB0A61463bA90424792363C2aEa6652"    // goerli
];

const ownkAddresses = [
    "",   // mumbai
    "0x223FeAAFE9880A6359dC32Bd9b647C010C9953d2"    // goerli
];

const peasAddresses = [
    "",   // mumbai
    "0xe5FAEba50BCD4E1fCf059558adeC8124E470a639"    // goerli
];

const pnftAddresses = [
    "",
    "0xe61407f2e48167008Abe8DEF35E7EAcb77b40023"    // goerli
];

const custAddresses = [
    
];

const treasury = "0xF0d096D33559cDc5f527435b82073c108D6c3107";
const gameWallet = "0xd5439F21fd46f2eA74563443626f0246E268983f";
const gamePlayV2 = "0x8004422baEb59146d548fb0C238848CCe4B1B31F";

const TokenTypes = {
    membershipNFT: 0,  // OWNDK
    peasNFT: 1,        // PEAS
    pnftSSNFT: 2,      // PNFT - SS
    pnftSNFT: 3,       // PNFT - S
    pnftANFT: 4,       // PNFT - A
    pnftBNFT: 5,       // PNFT - B
    pnftCNFT: 6,       // PNFT - C
    customNFT: 7
}

const PayTypes = {
    payAll: 0,         // Anything 
    payEther: 1,       // Ether / Matic
    payUSDC: 2,        // USDC
    payPBRT: 3,        // PBRT
    payFiat: 4         // Fiat USD
}

module.exports = {
    treasury, 
    pbrtTokenBalance, 
    nftTokenCount, 
    nftBuyers, 
    nftSellers, 
    usdcAddresses,
    pbrtAddresses,
    ownkAddresses,
    peasAddresses,
    custAddresses,
    pnftAddresses,
    gameWallet,
    gamePlayV2,
    TokenTypes,
    PayTypes
}