const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ethers } = require("hardhat");


describe("NFTEngine", function () {
  let engineInfo;
  let nftEngine;

  async function deployBaseContracts() {
    const [owner, seller, buyer, treasury] = await ethers.getSigners();

    const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    const erc721Mock = await ERC721Mock.deploy("Test NFT Token", "TNT");

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const erc20Mock = await ERC20Mock.deploy("Test ERC20 Token", "TET");

    const NFTEngineFactory = await ethers.getContractFactory("NFTEngineFactory");
    const nftEngineFactory = await NFTEngineFactory.deploy();

    return { nftEngineFactory, erc721Mock, erc20Mock, owner, seller, buyer, treasury };
  }

  before('Create Marketplaces', async () => {
    engineInfo = await loadFixture(deployBaseContracts);

    console.log("factory:", engineInfo.nftEngineFactory.address);
    console.log("erc721Mock:", engineInfo.erc721Mock.address);
    console.log("erc20Mock:", engineInfo.erc20Mock.address);
    console.log("seller:", engineInfo.seller.address);
    console.log("buyer:", engineInfo.buyer.address);
    console.log("treasury:", engineInfo.treasury.address);

    await engineInfo.nftEngineFactory.createNFTEngine(
      engineInfo.erc721Mock.address, 
      engineInfo.treasury.address
    );
    const engine = await engineInfo.nftEngineFactory.getNftEngineByContract(
      engineInfo.erc721Mock.address
    );

    const NFTEngine = await ethers.getContractFactory("NFTEngine");
    nftEngine = await NFTEngine.attach(engine);

    await engineInfo.erc721Mock.setMarketplace(engine);

    console.log("marketplace:", nftEngine.address);    
  });

  it ("Should initialize NFT Token and ERC20 Token", async () => {
    let tokenId = 0;
    let tokenPrice = ethers.utils.parseEther("5");
    await nftEngine.connect(engineInfo.seller).mintNFT(
      getZeroAddress(), tokenPrice, 0, "");
    await expect(await engineInfo.erc721Mock.ownerOf(tokenId)).to.be.equal(
      engineInfo.seller.address,  "Failed to mint NFT Token 1"
    );

    tokenId = 1;
    await nftEngine.connect(engineInfo.seller).mintNFT(
      getZeroAddress(), tokenPrice, 0, "");
    await expect(await engineInfo.erc721Mock.ownerOf(tokenId)).to.be.equal(
      engineInfo.seller.address,  "Failed to mint NFT Token 2"
    );

    const tokenBalance = ethers.utils.parseEther("100");
    await engineInfo.erc20Mock.mint(engineInfo.buyer.address, tokenBalance);
    await expect(await engineInfo.erc20Mock.balanceOf(engineInfo.buyer.address))
    .to.be.equal(
      tokenBalance,  "Failed to mint ERC20"
    );

    await showBalances();
  });

  it ("Should create two sales with two NFT tokens", async () => {
    let tokenId = 0;
    let tokenPrice = ethers.utils.parseEther("10");
    
    await engineInfo.erc721Mock.connect(engineInfo.seller).approve(
      nftEngine.address,
      tokenId);

    await nftEngine.connect(engineInfo.seller).createSale(
      tokenId,
      getZeroAddress(),
      tokenPrice,
      [],
      []
    );

    tokenId = 1;
    await engineInfo.erc721Mock.connect(engineInfo.seller).approve(
      nftEngine.address,
      tokenId);

    await nftEngine.connect(engineInfo.seller).createSale(
      tokenId,
      engineInfo.erc20Mock.address,
      tokenPrice,
      [],
      []
    );

    let nfts = await nftEngine.getTokensOnSale();
    await expect(nfts.length).to.be.equal(2, "Failed to create Sales, invalid sales count");

    const nftInfo = await nftEngine.getTokenSaleInfo(nfts[1]);
    await expect(nftInfo.price).to.be.equal(tokenPrice, "Failed to create a Sale, invalid token price");

    await showBalances();
  });

  it ("Should buy two NFT tokens from sales", async () => {
    let nfts = await nftEngine.getTokensOnSale();
    for (let i = 0; i < nfts.length; i++) {
      const nftInfo = await nftEngine.getTokenSaleInfo(nfts[i]);
      if (nftInfo.erc20Token == 0) {
        await nftEngine.connect(engineInfo.buyer).buyNFT(nfts[i], {value: nftInfo.price});        
      }
      else {
        await engineInfo.erc20Mock.connect(engineInfo.buyer).approve(
          nftEngine.address,
          nftInfo.price
        );
        await nftEngine.connect(engineInfo.buyer).buyNFT(nfts[i]);
      }  
    }
    await showBalances();
  });

  function getZeroAddress() {
    return "0x0000000000000000000000000000000000000000";
  }

  async function getERC20Balance(wallet) {
    const balance = await engineInfo.erc20Mock.balanceOf(wallet);
    return ethers.utils.formatEther(balance);
  }

  async function getEtherBalance(wallet) {
    const balance = await ethers.provider.getBalance(wallet);
    return ethers.utils.formatEther(balance);
  }

  async function showBalances() {
    console.log("[Checking balances]");
    console.log("\tSeller Erc20:", 
      await getERC20Balance(engineInfo.seller.address));
    console.log("\tBuyer Erc20:", 
      await getERC20Balance(engineInfo.buyer.address));
    console.log("\tTreasury Erc20:", 
      await getERC20Balance(engineInfo.treasury.address));

    const provider = ethers.provider;
    console.log("\tSeller Ether:", 
      await getEtherBalance(engineInfo.seller.address));
    console.log("\tBuyer Ether:", 
      await getEtherBalance(engineInfo.buyer.address));
    console.log("\tTreasury Ether:", 
      await getEtherBalance(engineInfo.treasury.address));
  }
  
});
