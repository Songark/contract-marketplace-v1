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
  chainHardhat,
  chainRinkeby,
  chainGanache
} = require("./constants");

async function main() {
  const [deployer, buyer, treasury] = await ethers.getSigners();

  console.log("Deploying contracts with this \nAccount address:", deployer.address,
    "\nAccount balance:", (await deployer.getBalance()).toString());

  console.log("Network:", network.name);

  // hardhat test | ganache chain
  const MembershipNFTMock = await ethers.getContractFactory("MembershipNFTMock");
  const OwndTokenMock = await ethers.getContractFactory("OwndTokenMock");
  const FractionalizedNFTMock = await ethers.getContractFactory("FractionalizedNFTMock");
  const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");

  const membershipNFTMock = (await MembershipNFTMock.deploy("Genesis Owner Key", "MNFT"));
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
        [deployer.address, treasury.address], 
        { initializer: 'initialize' });

    await nftEngineV1.deployed();
    await nftEngineV1.setNFTContracts(
        customNFTMock.address, 
        fractionalizedNFTMock.address, 
        membershipNFTMock.address, 
        owndTokenMock.address
    );
    await customNFTMock.setMarketplace(nftEngineV1.address);

    if (network.name == 'rinkeby') {
      let tokenCount = 10;
      await customNFTMock.mint(
        deployer.address, tokenCount
      );
      await membershipNFTMock.mint(
        deployer.address, tokenCount
      );
      let tokenBalance = 1000;
      await owndTokenMock.mint(
        deployer.address, tokenBalance
      );
      await owndTokenMock.mint(
        buyer.address, tokenBalance
      );
    }

    console.log("nftEngineV1:", nftEngineV1.address);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
