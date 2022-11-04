// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades } = require("hardhat");

const {
  pbrtTokenBalance, 
} = require("./constants");

const PBRTaddr = "0xb1677C5639CC483267cC720833d09e0ABd10000A";
const GamePlayV2 = "0x8004422baEb59146d548fb0C238848CCe4B1B31F";  // from Dai

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Minting PBRT Tokens to someone with this \nAccount address:", deployer.address);

  console.log("Network:", network.name);

  try {
      // hardhat test | ganache chain
      const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
      const pbrtToken = await PlayEstatesBrickToken.attach(PBRTaddr);
      
      console.log("PBRT:", pbrtToken.address);

      if (network.name == 'rinkeby' || network.name == "goerli") {   
        await pbrtToken.setGameEngine(GamePlayV2);           
      }
  } catch (error) {
      console.log(error);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
