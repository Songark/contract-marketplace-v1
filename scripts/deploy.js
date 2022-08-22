// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network } = require("hardhat");
const hre = require("hardhat");

const {
  nftMints, 
  ownedMints,
  chainHardhat,
  chainRinkeby
} = require("./constants");

async function main() {
  const [deployer, admin, treasury] = await ethers.getSigners();

  console.log("Deploying contracts with this \nAccount address:", deployer.address,
    "\nAccount balance:", (await deployer.getBalance()).toString());

  console.log("Network:", network.name, network.config.chainId);
  let membershipNFTMock;
  let owndTokenMock;
  let fractionalizedNFTMock;
  let customNFTMock;

  if (network.config.chainId == chainHardhat) {
    // hardhat test chain
    const MembershipNFTMock = await ethers.getContractFactory("MembershipNFTMock");
    const OwndTokenMock = await ethers.getContractFactory("OwndTokenMock");
    const FractionalizedNFTMock = await ethers.getContractFactory("FractionalizedNFTMock");
    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
  
    membershipNFTMock = (await MembershipNFTMock.deploy());
    owndTokenMock = (await OwndTokenMock.deploy());
    fractionalizedNFTMock = (await FractionalizedNFTMock.deploy());
    customNFTMock = (await CustomNFTMock.deploy("Custom NFT", "CNFT"));
  }
  else if (network.config.chainId == chainRinkeby) {
    // rinkeby test chain
    const MembershipNFTMock = await ethers.getContractFactory("MembershipNFTMock");
    const OwndTokenMock = await ethers.getContractFactory("OwndTokenMock");
    const FractionalizedNFTMock = await ethers.getContractFactory("FractionalizedNFTMock");
    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
  
    membershipNFTMock = (await MembershipNFTMock.deploy());
    owndTokenMock = (await OwndTokenMock.deploy());
    fractionalizedNFTMock = (await FractionalizedNFTMock.deploy());
    customNFTMock = (await CustomNFTMock.deploy("Custom NFT", "CNFT"));

    console.log("membershipNFTMock:", membershipNFTMock.address);
    console.log("fractionalizedNFTMock:", fractionalizedNFTMock.address);
    console.log("customNFTMock:", customNFTMock.address);
    console.log("owndTokenMock:", owndTokenMock.address);
  }

  if (membershipNFTMock != 0) {
    const NFTEngineFactory = await ethers.getContractFactory("NFTEngineFactory");
    const nftEngineFactory = await NFTEngineFactory.deploy();
    await nftEngineFactory.deployed();

    const _tx = await nftEngineFactory.createNFTEngine(admin.address, treasury.address);
    const _receipt = await _tx.wait();
    let _events = _receipt.events.filter((x) => {return x.event == "NFTEngineCreated"});   
    for (let i = 0; i < _events.length; i++){
      console.log("Emitted NFTEngineCreated:", _events[i].args[0]);

      const NFTEngine = await ethers.getContractFactory("NFTEngine");
      let nftEngine = await NFTEngine.attach(_events[i].args[0]);
      await nftEngine.setNFTContracts(
        customNFTMock.address, 
        fractionalizedNFTMock.address, 
        membershipNFTMock.address, 
        owndTokenMock.address
      );

      await customNFTMock.setMarketplace(nftEngine.address);
      await customNFTMock.safeMint(admin.address, nftMints);
      await membershipNFTMock.mint(admin.address, nftMints);      
      await owndTokenMock.mint(admin.address, ethers.utils.parseEther(ownedMints.toString()));
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
