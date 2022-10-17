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

const nftEngineV1 = '0x55DA14288c3f81BEBeCe29F593864Ea46a0985D7';

const membershipNFT = '0xb33ADf707DD1B911C11dc430826fDc43Ff68d636';
const customNFT = '0xdB7C468b7Ff33726B19c4F8b60c2eEc692FB4f61';
const pbrtToken = '0x76B17150fC0A65289a5b07dAD2538c26fBf4376c';

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
        await contractEngineV1.setPaymentContract(pbrtToken);
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