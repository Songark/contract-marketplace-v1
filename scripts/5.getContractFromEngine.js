// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades  } = require("hardhat");

const {
  TokenTypes_membershipNFT, 
  TokenTypes_customNFT,
  TokenTypes_erc20Token
} = require("./constants");

const nftEngineV1 = '0x878b6eE9784A6a08BAdc18c140C19C36bdb6e4A7'; // '0xea7b622083bBa4f542a4DFFbCE285B3edff31e0e';

async function main() {
    const [deployer, admin, treasury] = await ethers.getSigners();

    console.log("Querying contracts with this \nAccount address:", deployer.address,
        "\nAccount balance:", (await deployer.getBalance()).toString());

    console.log("Network:", network.name, network.config.chainId);
    try {
      const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
      const contractEngineV1 = await NFTEngineV1.attach(nftEngineV1);
  
      if (contractEngineV1 !== undefined) {
        const membershipNFT = await contractEngineV1.getContractAddress(TokenTypes_membershipNFT);
        const customNFT = await contractEngineV1.getContractAddress(TokenTypes_customNFT);
        const pbrtToken = await contractEngineV1.getContractAddress(TokenTypes_erc20Token);
        console.log("membershipNFT:", membershipNFT);
        console.log("customNFT:", customNFT);
        console.log("pbrtToken:", pbrtToken);
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
