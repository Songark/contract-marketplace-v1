const { ethers } = require("hardhat");

const oneDaySeconds = 24 * 60 * 60;

const increaseTime = async (secondsToIncrease) => {
    await ethers.provider.send('evm_increaseTime', [secondsToIncrease]);
    await ethers.provider.send('evm_mine', []);
};
  
module.exports = {
    increaseTime, oneDaySeconds
}
  