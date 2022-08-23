const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ethers, upgrades } = require("hardhat");

describe("NFT Marketplace", function () {
  let engineInfo;
  let nftEngine;

  async function deployBaseContracts() {
    const [owner, seller, buyer1, buyer2, treasury] = await ethers.getSigners();

    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
    const customNFTMock = await CustomNFTMock.deploy("Custom NFT Token", "CNT");

    const FractionalizedNFTMock = await ethers.getContractFactory("FractionalizedNFTMock");
    const fractionalizedNFTMock = await FractionalizedNFTMock.deploy();

    const OwndTokenMock = await ethers.getContractFactory("OwndTokenMock");
    const owndTokenMock = await OwndTokenMock.deploy();

    const MembershipNFTMock = await ethers.getContractFactory("MembershipNFTMock");
    const membershipNFTMock = await MembershipNFTMock.deploy();    

    const NFTEngineFactory = await ethers.getContractFactory("NFTEngineFactory");
    const nftEngineFactory = await NFTEngineFactory.deploy();
    await nftEngineFactory.deployed();

    const _tx = await nftEngineFactory.createNFTEngine(owner.address, treasury.address);
    const _receipt = await _tx.wait();
    let _events = _receipt.events.filter((x) => {return x.event == "NFTEngineCreated"});   
    await expect(_events.length).to.be.equal(1,  "Failed to create NFTEngine");

    for (let i = 0; i < _events.length; i++){
      console.log("NFTEngine Created:", _events[i].args[0]);

      const NFTEngine = await ethers.getContractFactory("NFTEngineV1");
      let nftEngine = await NFTEngine.attach(_events[i].args[0]);

      await nftEngine.setNFTContracts(
        customNFTMock.address, 
        fractionalizedNFTMock.address, 
        membershipNFTMock.address, 
        owndTokenMock.address
      );

      await expect(await nftEngine.getNFTContract(0)).to.be.equal(customNFTMock.address, 
        "Failed to set customNFT");
      await expect(await nftEngine.getNFTContract(1)).to.be.equal(fractionalizedNFTMock.address, 
        "Failed to set fractionalizedNFTMock");
      await expect(await nftEngine.getNFTContract(2)).to.be.equal(membershipNFTMock.address, 
        "Failed to set membershipNFTMock");
      await expect(await nftEngine.getNFTContract(3)).to.be.equal(owndTokenMock.address, 
        "Failed to set owndTokenMock");
    }

    return { 
      nftEngineFactory, 
      customNFTMock, 
      fractionalizedNFTMock,
      membershipNFTMock, 
      owndTokenMock, 
      owner, 
      seller, 
      buyer1,
      buyer2, 
      treasury 
    };
  }

  before('Create Marketplaces', async () => {
    // engineInfo = await loadFixture(deployBaseContracts);
    engineInfo = await deployBaseContracts();

    console.log("factory:", engineInfo.nftEngineFactory.address);
    console.log("customNFTMock:", engineInfo.customNFTMock.address);
    console.log("fractionalizedNFTMock:", engineInfo.fractionalizedNFTMock.address);
    console.log("membershipNFTMock:", engineInfo.membershipNFTMock.address);
    console.log("owndTokenMock:", engineInfo.owndTokenMock.address);
    console.log("seller:", engineInfo.seller.address);
    console.log("buyer1:", engineInfo.buyer1.address);
    console.log("buyer2:", engineInfo.buyer2.address);
    console.log("treasury:", engineInfo.treasury.address);

    const engine = await engineInfo.nftEngineFactory.getNftEngineByAdmin(
      engineInfo.owner.address
    );

    const NFTEngine = await ethers.getContractFactory("NFTEngineV1");
    nftEngine = await NFTEngine.attach(engine);

    await engineInfo.customNFTMock.setMarketplace(engine);

    console.log("Created Marketplace:", nftEngine.address);    
  });

  it ("Should mint customNFT tokens", async () => {
    // mint custom nft tokens
    let tokenOwner = engineInfo.seller.address;
    let tokenCount = 10;
    let tx = await engineInfo.customNFTMock.safeMint(
      tokenOwner, tokenCount
    );
    console.log("gas used (customNFTMock.safeMint):", (await tx.wait()).gasUsed.toString());
    await expect(await engineInfo.customNFTMock.balanceOf(tokenOwner)).to.be.equal(
      tokenCount,  "Failed to mint customNFT Token"
    );    
  });

  it ("Should mint fractionalizedNFT tokens", async () => {
    // mint fractionalized nft tokens
    
  });

  it ("Should mint membershipNFT tokens", async () => {
    // mint membership nft tokens
    let tokenOwner = engineInfo.seller.address;
    let tokenCount = 10;
    let tx = await engineInfo.membershipNFTMock.mint(
      tokenOwner, tokenCount
    );
    console.log("gas used (membershipNFTMock.mint):", (await tx.wait()).gasUsed.toString());
    await expect(await engineInfo.membershipNFTMock.balanceOf(tokenOwner)).to.be.equal(
      tokenCount,  "Failed to mint membershipNFTMock Token"
    );
  });

  it ("Should mint ownd tokens", async () => {
    // mint fractionalized nft tokens
    let tokenOwner = engineInfo.buyer1.address;
    let tokenBalance = ethers.utils.parseEther("1000");
    await engineInfo.owndTokenMock.mint(
      tokenOwner, tokenBalance
    );
    await expect(await engineInfo.owndTokenMock.balanceOf(tokenOwner)).to.be.equal(
      tokenBalance,  "Failed to mint owndTokenMock Token for buyer 1"
    );

    tokenOwner = engineInfo.buyer2.address;
    await engineInfo.owndTokenMock.mint(
      tokenOwner, tokenBalance
    );
    await expect(await engineInfo.owndTokenMock.balanceOf(tokenOwner)).to.be.equal(
      tokenBalance,  "Failed to mint owndTokenMock Token for buyer 2"
    );
  });

  it ("Should create a sale pricing 1 eth for one membershipNFT token", async () => {
    let seller = engineInfo.seller;
    let nftContract = engineInfo.membershipNFTMock;
    let tokenId = 1;
    let tokenPrice = ethers.utils.parseEther("1");
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    let tx = await nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      getZeroAddress(),
      tokenPrice,
      [],
      []
    );
    console.log("gas used (nftEngine.createSale):", (await tx.wait()).gasUsed.toString());

    let tokenSales = await nftEngine.getTokensOnSale(nftContract.address);
    await expect(tokenSales.length).to.be.equal(1, "Failed to create sales, invalid sales count");

    const tokenSaleInfo = await nftEngine.getTokenSaleInfo(nftContract.address, tokenSales[0]);
    await expect(tokenSaleInfo.price).to.be.equal(tokenPrice, "Failed to create a sale, invalid token price");
  });

  it ("Should create a sale pricing 10 owndTokens for one membershipNFT token", async () => {
    let seller = engineInfo.seller;
    let nftContract = engineInfo.membershipNFTMock;
    let tokenId = 2;
    let tokenPrice = ethers.utils.parseEther("10");
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    let tx = await nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      engineInfo.owndTokenMock.address,
      tokenPrice,
      [],
      []
    );
    console.log("gas used (nftEngine.createSale):", (await tx.wait()).gasUsed.toString());

    let tokenSales = await nftEngine.getTokensOnSale(nftContract.address);
    await expect(tokenSales.length).to.be.equal(2, "Failed to create sales, invalid sales count");

    const tokenSaleInfo = await nftEngine.getTokenSaleInfo(nftContract.address, tokenSales[1]);
    await expect(tokenSaleInfo.price).to.be.equal(tokenPrice, "Failed to create a sale, invalid token price");
  });

  it ("Should buy two NFTs from sales using 1 eth and 10 owndTokens", async () => {
    let nftContract = engineInfo.membershipNFTMock;    
    let tokenSales = await nftEngine.getTokensOnSale(nftContract.address);
    for (let i = 0; i < tokenSales.length; i++) {
      const saleInfo = await nftEngine.getTokenSaleInfo(nftContract.address, tokenSales[i]);
      if (saleInfo.erc20Token == 0) 
      {
        let tx = await nftEngine.connect(engineInfo.buyer1).buyNFT(
          nftContract.address, 
          tokenSales[i], 
          {value: saleInfo.price});     
        console.log("gas used (nftEngine.buyNFT):", (await tx.wait()).gasUsed.toString());

        await expect(await nftContract.ownerOf(tokenSales[i])).to.be.equal(
          engineInfo.buyer1.address, "Failed to buy NFT using 1 eth"
        );
      }
      else {
        await engineInfo.owndTokenMock.connect(engineInfo.buyer2).approve(
          nftEngine.address,
          saleInfo.price
        );
        let tx = await nftEngine.connect(engineInfo.buyer2).buyNFT(
          nftContract.address, 
          tokenSales[i]
        );
        console.log("gas used (nftEngine.buyNFT):", (await tx.wait()).gasUsed.toString());

        await expect(await nftContract.ownerOf(tokenSales[i])).to.be.equal(
          engineInfo.buyer2.address, "Failed to buy NFT using 10 ownedTokens"
        );
      }  
    }
  });

  it ("Should create two auctions pricing eth / owndTokens for one membershipNFT token", async () => {
    let seller = engineInfo.seller;
    let nftContract = engineInfo.membershipNFTMock;

    /// creating an auction with 10 ~ 100 owndTokens pricing
    let tokenId = 3;
    let minPrice = ethers.utils.parseEther("10");
    let buyNowPrice = ethers.utils.parseEther("100");
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    let tx = await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.owndTokenMock.address,
      minPrice,
      buyNowPrice,
      [],
      []
    );      
    console.log("gas used (nftEngine.createAuction):", (await tx.wait()).gasUsed.toString());

    /// creating an auction with 0.1 ~ 1 eth pricing
    tokenId = 4;
    minPrice = ethers.utils.parseEther("0.1");
    buyNowPrice = ethers.utils.parseEther("1");
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    tx = await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      getZeroAddress(),
      minPrice,
      buyNowPrice,
      [],
      []
    );  
    console.log("gas used (nftEngine.createAuction):", (await tx.wait()).gasUsed.toString());

    let tokenAuctions = await nftEngine.getTokensOnAuction(nftContract.address);
    await expect(tokenAuctions.length).to.be.equal(2, "Failed to create auctions, invalid auctions count");

    const tokenAuctionInfo = await nftEngine.getTokenAuctionInfo(nftContract.address, tokenAuctions[1]);
    await expect(tokenAuctionInfo.minPrice).to.be.equal(minPrice, "Failed to create an auction, invalid minPrice");
  });

  it ("Should make a bid pricing owndTokens for one membershipNFT token", async () => {
    let nftContract = engineInfo.membershipNFTMock;
    let erc20Contract = engineInfo.owndTokenMock;
    let tokenId = 3;
    let tokenAmount = ethers.utils.parseEther("50");
    
    // make bid with 50 owned token with buyer 1
    await erc20Contract.connect(engineInfo.buyer1).approve(
      nftEngine.address,
      tokenAmount
    );

    let tx = await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      erc20Contract.address,
      tokenAmount
    );
    console.log("gas used (nftEngine.makeBid):", (await tx.wait()).gasUsed.toString());

    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionBidMade')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.buyer1.address,
      0,
      erc20Contract.address,
      tokenAmount
    ); 
   

    // make bid with 90 owned token with buyer 2
    tokenAmount = ethers.utils.parseEther("90");
    await erc20Contract.connect(engineInfo.buyer2).approve(
      nftEngine.address,
      tokenAmount
    );

    tx = await nftEngine.connect(engineInfo.buyer2).makeBid(
      nftContract.address,
      tokenId,
      erc20Contract.address,
      tokenAmount
    );
    console.log("gas used (nftEngine.makeBid):", (await tx.wait()).gasUsed.toString());

    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionBidMade')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.buyer2.address,
      0,
      erc20Contract.address,
      tokenAmount
    ); 
  });

  it ("Should make a bid with buy now price ownedToken for completion auction", async () => {
    let nftContract = engineInfo.membershipNFTMock;
    let erc20Contract = engineInfo.owndTokenMock;
    let tokenId = 3;
    let tokenAmount = ethers.utils.parseEther("100");
    
    // make bid with 1 eth with buyer 1 (buy now price are 100 tokens)
    await erc20Contract.connect(engineInfo.buyer1).approve(
      nftEngine.address,
      tokenAmount
    );

    let tx = await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      erc20Contract.address,
      tokenAmount
    );
    console.log("gas used (nftEngine.makeBid):", (await tx.wait()).gasUsed.toString());

    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionPaid')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.seller.address,
      tokenAmount,
      engineInfo.buyer1.address,
      engineInfo.buyer1.address
    ); 

    await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
      engineInfo.buyer1.address,
      "Failed to transfer membershipNFT to highest bidder"
    )
  });

  it ("Should make a bid pricing Eth for one membershipNFT token", async () => {
    let nftContract = engineInfo.membershipNFTMock;
    let tokenId = 4;
    let ethAmount = ethers.utils.parseEther("0.5");
    
    // make bid with 0.5 eth with buyer 1
    let tx = await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      getZeroAddress(),
      0,
      {value: ethAmount}
    );
    console.log("gas used (nftEngine.makeBid):", (await tx.wait()).gasUsed.toString());

    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionBidMade')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.buyer1.address,
      ethAmount,
      getZeroAddress(),
      0
    ); 

    // make bid with 0.9 eth with buyer 2
    ethAmount = ethers.utils.parseEther("0.9");
    tx = await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      getZeroAddress(),
      0,
      {value: ethAmount}
    );
    console.log("gas used (nftEngine.makeBid):", (await tx.wait()).gasUsed.toString());
    
    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionBidMade')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.buyer1.address,
      ethAmount,
      getZeroAddress(),
      0
    ); 
  });  

  it ("Should make a bid with buy now price Eth for completion auction", async () => {
    let nftContract = engineInfo.membershipNFTMock;
    let tokenId = 4;
    let ethAmount = ethers.utils.parseEther("1");
    
    // make bid with 1 eth with buyer 1
    await expect(nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      getZeroAddress(),
      0,
      {value: ethAmount}
    ))
    .to.emit(nftEngine, 'NFTAuctionPaid')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.seller.address,
      ethAmount,
      engineInfo.buyer1.address,
      engineInfo.buyer1.address
    ); 

    await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
      engineInfo.buyer1.address,
      "Failed to transfer membershipNFT to highest bidder"
    )
  });  

  it ("Should test settle auction", async () => {
    let nftContract = engineInfo.membershipNFTMock;
    let tokenId = 4;
    
    await expect(nftEngine.connect(engineInfo.buyer1).settleAuction(
      nftContract.address,
      tokenId
    ))
    .to.revertedWith("Auction is finished or not created yet");
  });  

  

  function getZeroAddress() {
    return "0x0000000000000000000000000000000000000000";
  }

  async function getERC20Balance(wallet) {
    const balance = await engineInfo.owndTokenMock.balanceOf(wallet);
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
