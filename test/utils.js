const { ethers } = require("hardhat");

const oneDaySeconds = 24 * 60 * 60;
const TokenTypes_membershipNFT = 0;
const TokenTypes_customNFT = 1;
const TokenTypes_erc20Token = 2;
const nftTokenCount = 20;
const pbrtTokenBalance = 10000;

const increaseTime = async (secondsToIncrease) => {
    await ethers.provider.send('evm_increaseTime', [secondsToIncrease]);
    await ethers.provider.send('evm_mine', []);
};
  
module.exports = {
    increaseTime, 
    oneDaySeconds, 
    TokenTypes_membershipNFT, 
    TokenTypes_customNFT, 
    TokenTypes_erc20Token,
    nftTokenCount,
    pbrtTokenBalance
}
  