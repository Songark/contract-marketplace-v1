const { ethers } = require("hardhat");

const oneDaySeconds = 24 * 60 * 60;

const TokenTypes = {
    membershipNFT: 0,
    peasNFT: 1,
    pnftNFT: 2,
    customNFT: 3
}

const PayTypes = {
    payAll: 0,
    payEther: 1,
    payUSDC: 2,
    payPBRT: 3,
    payFiat: 4
}

const nftTokenCount = 20;
const pbrtTokenBalance = 10000;

const increaseTime = async (secondsToIncrease) => {
    await ethers.provider.send('evm_increaseTime', [secondsToIncrease]);
    await ethers.provider.send('evm_mine', []);
};
  
module.exports = {
    increaseTime, 
    oneDaySeconds, 
    TokenTypes, 
    PayTypes, 
    nftTokenCount,
    pbrtTokenBalance
}
  