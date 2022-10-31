// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades } = require("hardhat");

const {
  nftTokenCount, pbrtTokenBalance, 
  nftBuyers, 
  nftSellers,
  treasury,
  gameWallet,
  gamePlayV2,
  TokenTypes_membershipNFT,
  TokenTypes_customNFT
} = require("./constants");

async function main() {
  const [deployer] = await ethers.getSigners();
  const buyers = nftBuyers;
  buyers.push(deployer.address);

  const sellers = nftSellers;
  sellers.push(deployer.address);

  console.log("Deploying contracts with this \nAccount address:", deployer.address,
    "\nAccount balance:", (await deployer.getBalance()).toString());

  console.log("Network:", network.name);

  try {
      // hardhat test | ganache chain
      const MembershipNFT = await ethers.getContractFactory("MembershipNFT");
      const membershipNFT = await MembershipNFT.deploy("Genesis Owner Key", "MNFT");    
  
      const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
      const customNFT = await CustomNFTMock.deploy("Custom NFT Token", "CNT");
  
      const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
      const pbrtToken = await PlayEstatesBrickToken.deploy("PlayEstates Bricks Token", "PBRT");
      
      console.log("membershipNFT:", membershipNFT.address);
      console.log("customNFT:", customNFT.address);
      console.log("PBRT:", pbrtToken.address);

      const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
      const nftEngineV1 = await upgrades.deployProxy(
          NFTEngineV1, 
          [deployer.address, treasury], 
          { initializer: 'initialize' });
      await nftEngineV1.deployed();
      console.log("nftEngineV1:", nftEngineV1.address);  
      
      await nftEngineV1.setNFTContract(TokenTypes_membershipNFT, membershipNFT.address);
      await nftEngineV1.setNFTContract(TokenTypes_customNFT, customNFT.address);
      await nftEngineV1.setPaymentContract(pbrtToken.address);

      await pbrtToken.setMarketplaceEngine(nftEngineV1.address);
      await pbrtToken.grantRole(0x00, gamePlayV2);  
      await pbrtToken.setGameEngine(gameWallet);
      await pbrtToken.setMintRole(gameWallet);

      if (network.name == 'rinkeby' || network.name == "goerli") {              
        for (let i = 0; i < sellers.length; i++) {
          await membershipNFT.mint(
            sellers[i], nftTokenCount, 0
          );
        }

        await pbrtToken.mint(
          deployer.address, pbrtTokenBalance
        );
        for (let i = 0; i < buyers.length; i++) {
          await pbrtToken.mint(
            buyers[i], pbrtTokenBalance
          );
        }
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
