const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");
const { 
  increaseTime, 
  oneDaySeconds, 
  TokenTypes_membershipNFT, 
  TokenTypes_customNFT, 
  TokenTypes_erc20Token,
  nftTokenCount,
  pbrtTokenBalance } = require("./utils");

describe("NFT Marketplace", function () {
  let engineInfo;
  let nftEngine;
  let emptyFeeRecipients = [];
  let emptyFeePercentages = [];

  async function deployBaseContracts() {
    const [owner, seller1, seller2, buyer1, buyer2, treasury1, treasury2] = await ethers.getSigners();

    const MembershipNFT = await ethers.getContractFactory("MembershipNFT");
    const membershipNFT = await MembershipNFT.deploy("Genesis Owner Key", "MNFT");    

    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
    const customNFTMock = await CustomNFTMock.deploy("Custom NFT Token", "CNT");

    const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
    const pbrTokenMock = await PlayEstatesBrickToken.deploy("PlayEstates Bricks Token", "PBRT");

    const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
    const nftEngine = await upgrades.deployProxy(
        NFTEngineV1, 
        [owner.address, treasury1.address], 
        { initializer: 'initialize' });

    await nftEngine.deployed();
    await nftEngine.setNFTContract(TokenTypes_membershipNFT, membershipNFT.address);
    await nftEngine.setNFTContract(TokenTypes_customNFT, customNFTMock.address);
    await nftEngine.setPaymentContract(pbrTokenMock.address);

    await expect(await nftEngine.getContractAddress(TokenTypes_membershipNFT))
      .to.be.equal(membershipNFT.address, "Failed to set membershipNFT");
    await expect(await nftEngine.getContractAddress(TokenTypes_customNFT))
      .to.be.equal(customNFTMock.address, "Failed to set customNFTMock");
    await expect(await nftEngine.getContractAddress(TokenTypes_erc20Token))
      .to.be.equal(pbrTokenMock.address, "Failed to set pbrToken");
    
    await pbrTokenMock.setMarketplaceEngine(nftEngine.address);

    return { 
      nftEngine, 
      membershipNFT, 
      customNFTMock, 
      pbrTokenMock, 
      owner, 
      seller1, 
      seller2, 
      buyer1,
      buyer2, 
      treasury1, 
      treasury2 
    };
  }

  before('Create Marketplaces', async () => {
    engineInfo = await deployBaseContracts();
    nftEngine = engineInfo.nftEngine;

    emptyFeeRecipients.push(engineInfo.treasury1.address);
    emptyFeePercentages.push(100);

    emptyFeeRecipients.push(engineInfo.treasury2.address);
    emptyFeePercentages.push(100);
  });

  it ("Should revert the set contracts", async () => {
    await expect(nftEngine.setNFTContract(
      TokenTypes_membershipNFT, ethers.constants.AddressZero
    )).to.be.reverted;  // Invalid nft contract address

    await expect(nftEngine.setNFTContract(
      10, engineInfo.membershipNFT.address
    )).to.be.reverted;  // Invalid nft type

    await expect(nftEngine.setPaymentContract(
      ethers.constants.AddressZero
    )).to.be.reverted;  // Invalid payment token address
  });

  it ("Should mint customNFT tokens", async () => {
    // mint custom nft tokens
    let tokenId = 1;
    let tokenOwner = engineInfo.seller1.address;    
    let tx = await engineInfo.customNFTMock.mint(
      tokenOwner, tokenId
    );
    await expect(await engineInfo.customNFTMock.balanceOf(tokenOwner)).to.be.equal(
      1,  "Failed to mint customNFT Token"
    );    
  });

  it ("Should mint membershipNFT tokens", async () => {
    // mint membership nft tokens
    let tokenOwner = engineInfo.seller1.address;    
    let tx = await engineInfo.membershipNFT.mint(
      tokenOwner, nftTokenCount, 0
    );
    await expect(await engineInfo.membershipNFT.balanceOf(tokenOwner)).to.be.equal(
      nftTokenCount,  "Failed to mint membershipNFT Token"
    );
  });

  it ("Should mint pbrt tokens", async () => {
    // mint fractionalized nft tokens
    let tokenOwner = engineInfo.buyer1.address;    
    await engineInfo.pbrTokenMock.mint(
      tokenOwner, pbrtTokenBalance
    );
    await expect(await engineInfo.pbrTokenMock.balanceOf(tokenOwner)).to.be.equal(
      pbrtTokenBalance,  "Failed to mint pbrTokenMock Token for buyer 1"
    );

    tokenOwner = engineInfo.buyer2.address;
    await engineInfo.pbrTokenMock.mint(
      tokenOwner, pbrtTokenBalance
    );
    await expect(await engineInfo.pbrTokenMock.balanceOf(tokenOwner)).to.be.equal(
      pbrtTokenBalance,  "Failed to mint pbrTokenMock Token for buyer 2"
    );
  });

  it ("Should create a sale pricing 1 eth for one membershipNFT token", async () => {
    let seller = engineInfo.seller1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 1;
    let tokenPrice = 1;
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    let tx = await nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    );

    let tokenSales = await nftEngine.getTokenInfosOnSale(nftContract.address);
    await expect(tokenSales.length).to.be.equal(1, "Failed to create sales, invalid sales count");

    let tokenSale = await nftEngine.getTokenSaleInfo(nftContract.address, tokenId);
    await expect(tokenSale.tokenId).to.be.equal(tokenId, "Failed to get token sale info");

    await expect(nftEngine.getTokenSaleInfo(nftContract.address, 100)).to.be.reverted; // 
  });

  it ("Should revert the create sale because of several reasons", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 2;
    let tokenPrice = 10;

    await expect(nftEngine.connect(buyer).createSale(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // onlyTokenOwner

    await expect(nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // onlyApprovedToken
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );    

    await expect(nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // onlyValidPrice

    await expect(nftEngine.connect(seller).createSale(
      ethers.constants.AddressZero,
      tokenId,
      engineInfo.pbrTokenMock.address,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // Unregistered nft contract

    await expect(nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      seller.address,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // Unregistered payment contract
  });

  it ("Should revert the buy nft because of several reasons", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 10;

    await expect(nftEngine.connect(buyer).buyNFT(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // onlySale

    tokenId = 1;
    await expect(nftEngine.connect(seller).buyNFT(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // onlyNotSaleSeller
  });

  it ("Should revert the buy nft with insufficient balance", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 1;

    await expect(nftEngine.connect(buyer).buyNFT(
      nftContract.address,
      tokenId,
      {value: 0}
    )).to.be.reverted;  // onlyNotSaleSeller
  });

  it ("Should test the withdraw sale", async () => {
    let seller = engineInfo.seller1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 2;
    let tokenPrice = 10;

    await expect(nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.emit(nftEngine, 'NFTTokenSaleCreated'); 

    await expect(nftEngine.connect(seller).withdrawSale(
      nftContract.address,
      tokenId
    )).to.emit(nftEngine, 'NFTTokenSaleWithdrawn'); 

    await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
      engineInfo.seller1.address, "Failed to withdrawSale"
    );
  });

  it ("Should revert the withdraw sale because of some reasons", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 2;

    await expect(nftEngine.connect(buyer).withdrawSale(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // onlySaleSeller

    await expect(nftEngine.connect(seller).withdrawSale(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // onlySaleSeller
  });

  it ("Should create a sale pricing 10 pbrtTokens for one membershipNFT token", async () => {
    let seller = engineInfo.seller1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 2;
    let tokenPrice = 10;
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );   

    let tx = await nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      tokenPrice,
      emptyFeeRecipients,
      emptyFeePercentages
    );

    let tokenSales = await nftEngine.getTokenInfosOnSale(nftContract.address);
    await expect(tokenSales.length).to.be.equal(2, "Failed to create sales, invalid sales count");
  });

  it ("Should buy two NFTs from sales using 1 eth and 10 pbrtTokens", async () => {
    let nftContract = engineInfo.membershipNFT;    
    let tokenSales = await nftEngine.getTokenInfosOnSale(nftContract.address);
    for (let i = 0; i < tokenSales.length; i++) {
      const saleInfo = tokenSales[i];
      if (saleInfo.erc20Token == 0) 
      {
        let tx = await nftEngine.connect(engineInfo.buyer1).buyNFT(
          nftContract.address, 
          saleInfo.tokenId, 
          {value: saleInfo.price});     

        await expect(await nftContract.ownerOf(saleInfo.tokenId)).to.be.equal(
          engineInfo.buyer1.address, "Failed to buy NFT using 1 eth"
        );
      }
      else {
        await engineInfo.pbrTokenMock.connect(engineInfo.buyer2).approve(
          nftEngine.address,
          saleInfo.price
        );
        let tx = await nftEngine.connect(engineInfo.buyer2).buyNFT(
          nftContract.address, 
          saleInfo.tokenId
        );

        await expect(await nftContract.ownerOf(saleInfo.tokenId)).to.be.equal(
          engineInfo.buyer2.address, "Failed to buy NFT using 10 pbrt Tokens"
        );
      }  
    }
  });

  it ("Should create two auctions pricing eth / pbrtTokens for one membershipNFT token", async () => {
    let seller = engineInfo.seller1;
    let nftContract = engineInfo.membershipNFT;

    /// creating an auction with 10 ~ 100 pbrtTokens pricing
    let tokenId = 3;
    let minPrice = 10;
    let buyNowPrice = 100;
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    let tx = await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    );      
    expect(await nftContract.ownerOf(tokenId)).to.equal(seller.address);

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
      ethers.constants.AddressZero,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    );  

    let tokenAuctions = await nftEngine.getTokenInfosOnAuction(nftContract.address);
    await expect(tokenAuctions.length).to.be.equal(2, "Failed to create auctions, invalid auctions count");

    let tokenAuction = await nftEngine.getTokenAuctionInfo(nftContract.address, tokenId);
    await expect(tokenAuction.tokenId).to.be.equal(tokenId, "Failed to get token auction info");

    await expect(nftEngine.getTokenAuctionInfo(nftContract.address, 100)).to.be.reverted; // 
  });

  it ("Should revert the create auction because of several reasons", async () => {
    let seller = engineInfo.seller1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 3;
    let minPrice = 10;
    let buyNowPrice = 100;
    
    await expect(nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // NFTEngineSellerCant, already created

    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await expect(nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      seller.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;   // Unregistered payment contract
    
    await expect(nftEngine.connect(seller).createAuction(
      ethers.constants.AddressZero,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;   // Unregistered nft contract

    tokenId = 2;
    await expect(nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // NFTEngineNotTokenOwner

    tokenId = 5;
    emptyFeePercentages.push(10000);
    await expect(nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // checkSizeRecipientsAndRates

    emptyFeeRecipients.push(engineInfo.treasury1.address);
    await expect(nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      buyNowPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // checkFeeRatesLessThanMaximum

    emptyFeeRecipients.pop();
    emptyFeePercentages.pop();

    await expect(nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      engineInfo.pbrTokenMock.address,
      minPrice,
      minPrice,
      0,
      emptyFeeRecipients,
      emptyFeePercentages
    )).to.be.reverted;  // NFTEngineInvalidMinPrice
  });

  it ("Should make a bid pricing pbrtTokens for one membershipNFT token", async () => {
    let nftContract = engineInfo.membershipNFT;
    let erc20Contract = engineInfo.pbrTokenMock;
    let tokenId = 3;
    let tokenAmount = 50;
    
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
    tokenAmount = 90;
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

  it ("Should make a bid with buy now price pbrtToken for completion auction", async () => {
    let nftContract = engineInfo.membershipNFT;
    let erc20Contract = engineInfo.pbrTokenMock;
    let tokenId = 3;
    let tokenAmount = 100;
    
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

    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionPaid')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.seller1.address,
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
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 4;
    let ethAmount = ethers.utils.parseEther("0.5");
    
    // make bid with 0.5 eth with buyer 1
    let tx = await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    );

    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionBidMade')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.buyer1.address,
      ethAmount,
      ethers.constants.AddressZero,
      0
    ); 

    await expect(nftEngine.connect(engineInfo.buyer2).withdrawBid(
      nftContract.address, 
      tokenId
    )).to.be.reverted;  // NFTEngineNotHighestBidder

    await expect(nftEngine.connect(engineInfo.buyer1).withdrawBid(
      nftContract.address, 
      tokenId
    )).to.emit(nftEngine, 'NFTAuctionBidWithdrawn');

    // make bid with 0.9 eth with buyer 2
    ethAmount = ethers.utils.parseEther("0.9");
    tx = await nftEngine.connect(engineInfo.buyer2).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    );
    
    expect(tx)
    .to.emit(nftEngine, 'NFTAuctionBidMade')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.buyer2.address,
      ethAmount,
      ethers.constants.AddressZero,
      0
    ); 
  });  

  it ("Should make a bid with buy now price Eth for completion auction", async () => {
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 4;
    let ethAmount = ethers.utils.parseEther("1");
    
    // make bid with 1 eth with buyer 1
    await expect(nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    ))
    .to.emit(nftEngine, 'NFTAuctionPaid')
    .withArgs(
      nftContract.address, 
      tokenId,
      engineInfo.seller1.address,
      ethAmount,
      engineInfo.buyer1.address,
      engineInfo.buyer1.address
    ); 

    await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
      engineInfo.buyer1.address,
      "Failed to transfer membershipNFT to highest bidder"
    )
  });  

  it ("Should revert the makebid becase of some reasosn", async () => {
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 5;
    let ethAmount = ethers.utils.parseEther("1");
    let minPrice = ethers.utils.parseEther("0.5");
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    
    await expect(nftEngine.connect(buyer).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    )).to.be.reverted;  // onlyNotAuctionSeller

    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      minPrice,
      ethAmount,
      oneDaySeconds,
      emptyFeeRecipients,
      emptyFeePercentages
    );  

    await expect(nftEngine.connect(engineInfo.buyer2).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0
    )).to.be.reverted;  // NFTEngineNotAcceptablePayment

    await nftEngine.connect(engineInfo.buyer2).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: minPrice}
    );

    await expect(nftEngine.connect(buyer).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: minPrice}
    )).to.be.reverted;  // Insufficient funds to bid
    
    await increaseTime(oneDaySeconds);

    await expect(nftEngine.connect(buyer).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    )).to.be.reverted;  // NFTEngineAuctionFinished
  });  

  it ("Should test settle auction", async () => {
    // create new auction again for withdraw testing
    const nftContract = engineInfo.membershipNFT;
    const tokenId = 10;
    const minPrice = ethers.utils.parseEther("0.1");
    const buyNowPrice = ethers.utils.parseEther("1");
    const ethAmount = ethers.utils.parseEther("0.5");
    const seller = engineInfo.seller1;

    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      minPrice,
      buyNowPrice,
      oneDaySeconds,
      emptyFeeRecipients,
      emptyFeePercentages
    );  

    await expect(nftEngine.connect(seller).settleAuction(
      nftContract.address,
      tokenId
    )).to.be.reverted;

    await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    );

    await expect(nftEngine.connect(seller).settleAuction(
      nftContract.address,
      tokenId
    )).to.emit(nftEngine, 'NFTAuctionSettled');
  });   

  it ("Should test withdraw auction", async () => {
    // create new auction again for withdraw testing
    const nftContract = engineInfo.membershipNFT;
    const tokenId = 11;
    const minPrice = ethers.utils.parseEther("0.1");
    const buyNowPrice = ethers.utils.parseEther("1");
    const seller = engineInfo.seller1;

    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      minPrice,
      buyNowPrice,
      oneDaySeconds,
      emptyFeeRecipients,
      emptyFeePercentages
    );  

    // withdraw auction by seller
    await expect(nftEngine.connect(seller).withdrawAuction(
      nftContract.address,
      tokenId
    )).to.be.emit(nftEngine, 'NFTAuctionWithdrawn');

    await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
      seller.address, "Failed to withdrawAuction action"
    );

  });

  it ("Should test takehighestbid auction", async () => {
    // create new auction again for withdraw testing
    const nftContract = engineInfo.membershipNFT;
    const tokenId = 12;
    const minPrice = ethers.utils.parseEther("0.1");
    const buyNowPrice = ethers.utils.parseEther("1");
    const ethAmount = ethers.utils.parseEther("0.5");
    const seller = engineInfo.seller1;

    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await nftEngine.connect(seller).createAuction(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      minPrice,
      buyNowPrice,
      oneDaySeconds,
      emptyFeeRecipients,
      emptyFeePercentages
    );  

    await expect(nftEngine.connect(seller).takeHighestBid(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // NFTEngineDidNotBid

    await nftEngine.connect(engineInfo.buyer1).makeBid(
      nftContract.address,
      tokenId,
      ethers.constants.AddressZero,
      0,
      {value: ethAmount}
    );

    await expect(nftEngine.connect(seller).takeHighestBid(
      nftContract.address,
      tokenId
    )).to.emit(nftEngine, 'NFTAuctionHighestBidTaken');

    await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
      engineInfo.buyer1.address, "Failed to takeHighestBid action"
    );
  });

  it ("Should revert the takehighestbid because of several reasons", async () => {
    // create new auction again for withdraw testing
    const nftContract = engineInfo.membershipNFT;
    const tokenId = 13;
    const seller = engineInfo.seller1;
    const buyer = engineInfo.buyer1;

    await expect(nftEngine.connect(buyer).takeHighestBid(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // onlyAuctionSeller

    await expect(nftEngine.connect(seller).takeHighestBid(
      nftContract.address,
      tokenId
    )).to.be.reverted;  // onlyAuctionSeller (not auctioning now)
  });

  it ("Should test remove many sales and auctions for checking gas", async () => {
    // create new auction again for withdraw testing
    const nftContract = engineInfo.membershipNFT;    
    const minPrice = 1;
    const buyNowPrice = 10;
    const seller = engineInfo.seller1;

    await engineInfo.membershipNFT.mint(
      seller.address, nftTokenCount, 0
    );

    for (let i = 0; i < nftTokenCount; i++) {
      const tokenId = i + nftTokenCount;
      await nftContract.connect(seller).approve(
        nftEngine.address,  
        tokenId      
      );
  
      await nftEngine.connect(seller).createSale(
        nftContract.address,
        tokenId,
        engineInfo.pbrTokenMock.address,
        buyNowPrice,
        emptyFeeRecipients,
        emptyFeePercentages
      );
    }
    
    for (let i = 0; i < nftTokenCount; i++) {
      const tokenId = i + nftTokenCount;
      await nftEngine.connect(seller).withdrawSale(
        nftContract.address,
        tokenId
      );
    }

    for (let i = 0; i < nftTokenCount; i++) {
      const tokenId = i + nftTokenCount;
      await nftContract.connect(seller).approve(
        nftEngine.address,  
        tokenId      
      );
  
      await nftEngine.connect(seller).createAuction(
        nftContract.address,
        tokenId,
        engineInfo.pbrTokenMock.address,
        minPrice,
        buyNowPrice,
        0,
        emptyFeeRecipients,
        emptyFeePercentages
      );
    }
    
    for (let i = 0; i < nftTokenCount; i++) {
      const tokenId = i + nftTokenCount;
      await nftEngine.connect(seller).withdrawAuction(
        nftContract.address,
        tokenId
      );
    }    
  });

  async function getERC20Balance(wallet) {
    const balance = await engineInfo.pbrTokenMock.balanceOf(wallet);
    return ethers.utils.formatEther(balance);
  }

  async function getEtherBalance(wallet) {
    const balance = await ethers.provider.getBalance(wallet);
    return ethers.utils.formatEther(balance);
  }
  
});
