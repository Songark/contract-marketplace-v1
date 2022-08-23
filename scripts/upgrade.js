// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, network, upgrades  } = require("hardhat");

const {
  nftMints, 
  ownedMints,
  chainHardhat,
  chainRinkeby,
  chainGanache
} = require("./constants");

const nftEngineV1 = '0x55DA14288c3f81BEBeCe29F593864Ea46a0985D7';

const membershipNFTMock = '0xb33ADf707DD1B911C11dc430826fDc43Ff68d636';
const fractionalizedNFTMock = '0x3a2cb58527eAB7bd203Bc1bb1548FF2596863746';
const customNFTMock = '0xdB7C468b7Ff33726B19c4F8b60c2eEc692FB4f61';
const owndTokenMock = '0x76B17150fC0A65289a5b07dAD2538c26fBf4376c';

async function main() {
    const [deployer, admin, treasury] = await ethers.getSigners();

    console.log("Upgrading contracts with this \nAccount address:", deployer.address,
        "\nAccount balance:", (await deployer.getBalance()).toString());

    console.log("Network:", network.name, network.config.chainId);
    console.log("membershipNFTMock:", membershipNFTMock);
    console.log("fractionalizedNFTMock:", fractionalizedNFTMock);
    console.log("customNFTMock:", customNFTMock);
    console.log("owndTokenMock:", owndTokenMock);

    const NFTEngineV2 = await ethers.getContractFactory("NFTEngineV2");
    const nftEngineV2 = await upgrades.upgradeProxy(
        nftEngineV1,
        NFTEngineV2);
    await nftEngineV2.deployed();

    await nftEngineV2.setNFTContracts(
        customNFTMock, 
        fractionalizedNFTMock, 
        membershipNFTMock, 
        owndTokenMock
    );

    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
    const customNFTMockContract = await CustomNFTMock.attach(customNFTMock);
    await customNFTMockContract.setMarketplace(nftEngineV2.address);
    console.log("nftEngineV2:", nftEngineV2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
