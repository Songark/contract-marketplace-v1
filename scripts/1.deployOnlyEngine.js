// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades } = require("hardhat");

const {
  nftBuyers, 
  nftSellers,
  treasury,
  TokenTypes_membershipNFT,
  TokenTypes_customNFT
} = require("./constants");

const membershipNFT = '0xc08BA1198fA68aA12BBa73C1c5b3FCB6243cbe6a';
const customNFT = '0xCBDC5Eb81AF6c156c49341C2B12b998849992463';
const pbrtToken = '0xb1677C5639CC483267cC720833d09e0ABd10000A';

async function main() {
  const [deployer] = await ethers.getSigners();
  const buyers = nftBuyers;
  buyers.push(deployer.address);

  const sellers = nftSellers;
  sellers.push(deployer.address);

  console.log("Deploying Engine with this \nAccount address:", deployer.address,
    "\nAccount balance:", (await deployer.getBalance()).toString());

  console.log("Network:", network.name);

  try {
      // hardhat test | ganache chain
      console.log("membershipNFT:", membershipNFT);
      console.log("customNFT:", customNFT);
      console.log("PBRT:", pbrtToken);

      const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
      const nftEngineV1 = await upgrades.deployProxy(
          NFTEngineV1, 
          [deployer.address, treasury], 
          { initializer: 'initialize' });
      await nftEngineV1.deployed();
      console.log("nftEngineV1:", nftEngineV1.address);  
      
      await nftEngineV1.setNFTContract(TokenTypes_membershipNFT, membershipNFT);
      await nftEngineV1.setNFTContract(TokenTypes_customNFT, customNFT);
      await nftEngineV1.setPaymentContract(pbrtToken, true);

      const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
      const pbrtTokenContract = await PlayEstatesBrickToken.attach(pbrtToken);

      await pbrtTokenContract.setMarketplaceEngine(nftEngineV1.address);

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
