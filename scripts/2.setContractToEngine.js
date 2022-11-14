// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades  } = require("hardhat");

const {
  TokenTypes_membershipNFT, 
  TokenTypes_customNFT
} = require("./constants");

const nftEngineV1 = '0x878b6eE9784A6a08BAdc18c140C19C36bdb6e4A7';

const membershipNFT = '0xc08BA1198fA68aA12BBa73C1c5b3FCB6243cbe6a';
const customNFT = '0xCBDC5Eb81AF6c156c49341C2B12b998849992463';
const pbrtToken = '0xb1677C5639CC483267cC720833d09e0ABd10000A';

async function main() {
    const [deployer, admin, treasury] = await ethers.getSigners();

    console.log("Upgrading contracts with this \nAccount address:", deployer.address,
        "\nAccount balance:", (await deployer.getBalance()).toString());

    console.log("Network:", network.name, network.config.chainId);
    console.log("membershipNFT:", membershipNFT);
    console.log("customNFT:", customNFT);
    console.log("pbrtToken:", pbrtToken);

    try {
      const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
      const contractEngineV1 = await NFTEngineV1.attach(nftEngineV1);
  
      if (contractEngineV1 !== undefined) {
        await contractEngineV1.setNFTContract(TokenTypes_membershipNFT, membershipNFT);
        await contractEngineV1.setNFTContract(TokenTypes_customNFT, customNFT);
        await contractEngineV1.setPaymentContract(pbrtToken, true);
        console.log("nftEngineV1 updated NFTs:");
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
