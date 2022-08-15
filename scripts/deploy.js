// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network } = require("hardhat");
const hre = require("hardhat");

async function main() {
  const [deployer, admin, treasury] = await ethers.getSigners();

  console.log("Deploying contracts with this \nAccount address:", deployer.address,
    "\nAccount balance:", (await deployer.getBalance()).toString());

  console.log("Network:", network.name, network.config.chainId);
  let membershipNFTMock = 0x0;
  let owndTokenMock = 0x0;
  let fractionalizedNFTMock = 0x0;
  let customNFTMock = 0x0;

  if (network.config.chainId == 31337) {
    // hardhat test chain
    const MembershipNFTMock = await ethers.getContractFactory("MembershipNFTMock");
    const OwndTokenMock = await ethers.getContractFactory("OwndTokenMock");
    const FractionalizedNFTMock = await ethers.getContractFactory("FractionalizedNFTMock");
    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
  
    membershipNFTMock = (await MembershipNFTMock.deploy()).address;
    owndTokenMock = (await OwndTokenMock.deploy()).address;
    fractionalizedNFTMock = (await FractionalizedNFTMock.deploy()).address;
    customNFTMock = (await CustomNFTMock.deploy("Custom NFT", "CNFT")).address;  
  }
  else if (network.config.chainId == 4) {
    // rinkeby test chain

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
        customNFTMock, fractionalizedNFTMock, membershipNFTMock, owndTokenMock
      );
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
