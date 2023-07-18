// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades } = require("hardhat");

const {
  treasury,
  pbrtTokenBalance, 
  nftTokenCount, 
  nftBuyers, 
  nftSellers,
  usdcAddresses,
  pbrtAddresses,
  ownkAddresses,
  peasAddresses,
  pnftAddresses,
  gameWallet,
  gamePlayV2,
  TokenTypes,
  PayTypes
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

  let addrIndex = 0;
  if (network.name == 'goerli' || network.name == 'hardhat') {
    addrIndex = 1;
  } 
  else if (network.name != 'mumbai') {
    console.log("Unsupported network: exit");
    return;
  }

  try {
      // hardhat test | ganache chain
      const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
      const customNFT = await CustomNFTMock.deploy("Custom NFT Token", "CUST");

      console.log("ownk:", ownkAddresses[addrIndex]);
      console.log("peas:", peasAddresses[addrIndex]);
      console.log("custom:", customNFT.address);
      console.log("pnft:", pnftAddresses[addrIndex]);
      console.log("pbrt:", pbrtAddresses[addrIndex]);
      console.log("usdc:", usdcAddresses[addrIndex]);

      const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
      const nftEngineV1 = await upgrades.deployProxy(
          NFTEngineV1, 
          [deployer.address, treasury], 
          { initializer: 'initialize' });
      await nftEngineV1.deployed();
      console.log("nftEngineV1:", nftEngineV1.address);  
      
      await nftEngineV1.setNFTContract(TokenTypes.membershipNFT, ownkAddresses[addrIndex]);
      await nftEngineV1.setNFTContract(TokenTypes.peasNFT, peasAddresses[addrIndex]);
      await nftEngineV1.setNFTContract(TokenTypes.customNFT, customNFT.address);
      await nftEngineV1.setNFTContract(TokenTypes.pnftSSNFT, pnftAddresses[addrIndex]);

      await nftEngineV1.setPaymentContract(PayTypes.payUSDC, usdcAddresses[addrIndex]);
      await nftEngineV1.setPaymentContract(PayTypes.payPBRT, pbrtAddresses[addrIndex]);

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
