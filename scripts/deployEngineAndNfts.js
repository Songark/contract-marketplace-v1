// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades } = require("hardhat");

const {
  nftMints, 
  ownedMints,
  nftBuyers, 
  nftSellers,
  treasury
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
      const MembershipNFTMock = await ethers.getContractFactory("MembershipNFTMock");
      const OwndTokenMock = await ethers.getContractFactory("OwndTokenMock");
      const FractionalizedNFTMock = await ethers.getContractFactory("FractionalizedNFTMock");
      const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");

      const membershipNFTMock = (await MembershipNFTMock.deploy("Genesis Owner Key", "OWNK"));
      const owndTokenMock = (await OwndTokenMock.deploy("Owned Token", "OWND"));
      const fractionalizedNFTMock = (await FractionalizedNFTMock.deploy());
      const customNFTMock = (await CustomNFTMock.deploy("Custom NFT", "CNFT"));
      
      console.log("customNFTMock:", customNFTMock.address);
      console.log("fractionalizedNFTMock:", fractionalizedNFTMock.address);
      console.log("membershipNFTMock:", membershipNFTMock.address);
      console.log("owndTokenMock:", owndTokenMock.address);

      if (membershipNFTMock != 0) {
        const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
        const nftEngineV1 = await upgrades.deployProxy(
            NFTEngineV1, 
            [deployer.address, treasury], 
            { initializer: 'initialize' });
        await nftEngineV1.deployed();
        console.log("nftEngineV1:", nftEngineV1.address);  
        
        await nftEngineV1.setNFTContracts(
            customNFTMock.address, 
            fractionalizedNFTMock.address, 
            membershipNFTMock.address, 
            owndTokenMock.address
        );
        await customNFTMock.setMarketplace(nftEngineV1.address);

        if (network.name == 'rinkeby' || network.name == "goerli") {      
          await customNFTMock.mint(
            deployer.address, nftMints
          );

          for (let i = 0; i < sellers.length; i++) {
            await membershipNFTMock.mint(
              sellers[i], nftMints, 0
            );
          }

          await owndTokenMock.mint(
            deployer.address, ownedMints
          );
          for (let i = 0; i < buyers.length; i++) {
            await owndTokenMock.mint(
              buyers[i], ownedMints / 10
            );
          }
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
