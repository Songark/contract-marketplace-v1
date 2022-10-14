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
  TokenTypes_membershipNFT,
  TokenTypes_customNFT,
  TokenTypes_erc20Token
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
      const customNFTMock = await CustomNFTMock.deploy("Custom NFT Token", "CNT");
  
      const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
      const pbrTokenMock = await PlayEstatesBrickToken.deploy("PlayEstates Bricks Token", "PBRT");
      
      console.log("customNFTMock:", customNFTMock.address);
      console.log("membershipNFT:", membershipNFT.address);
      console.log("PBRT:", pbrTokenMock.address);

      const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
      const nftEngineV1 = await upgrades.deployProxy(
          NFTEngineV1, 
          [deployer.address, treasury], 
          { initializer: 'initialize' });
      await nftEngineV1.deployed();
      console.log("nftEngineV1:", nftEngineV1.address);  
      
      await nftEngineV1.setNFTContract(TokenTypes_membershipNFT, membershipNFT.address);
      await nftEngineV1.setNFTContract(TokenTypes_customNFT, customNFTMock.address);
      await nftEngineV1.setPaymentContract(pbrTokenMock.address);

      await pbrTokenMock.setMarketplaceEngine(nftEngineV1.address);

      if (network.name == 'rinkeby' || network.name == "goerli") {              
        for (let i = 0; i < sellers.length; i++) {
          let customTokenId = 1;
          for (let j = 0; j < nftTokenCount; j++) {
            await customNFTMock.mint(
              sellers[i], customTokenId
            );  
            customTokenId++;
          }

          await membershipNFT.mint(
            sellers[i], nftTokenCount, 0
          );
        }

        await PlayEstatesBrickToken.mint(
          deployer.address, ownedMints
        );
        for (let i = 0; i < buyers.length; i++) {
          await pbrTokenMock.mint(
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
