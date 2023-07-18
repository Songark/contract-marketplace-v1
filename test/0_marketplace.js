const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");
const { 
  increaseTime, 
  oneDaySeconds, 
  TokenTypes,
  PayTypes,
  nftTokenCount,
  pbrtTokenBalance } = require("./utils");

describe("NFT Marketplace", function () {
  let engineInfo;
  let nftEngine;
  let emptyFeeRecipients = [];
  let emptyFeePercentages = [];
  let nftContracts = [];
  let payTypes = [PayTypes.payEther, PayTypes.payUSDC, PayTypes.payPBRT, PayTypes.payFiat];

  async function deployBaseContracts() {
    const [owner, seller1, seller2, buyer1, buyer2, treasury1, treasury2] = await ethers.getSigners();    

    const MembershipNFT = await ethers.getContractFactory("MembershipNFT");
    const membershipNFT = await MembershipNFT.deploy("Genesis Owner Key", "OWNK");    

    const PeasNFT = await ethers.getContractFactory("PeasNFT");
    const peasNFT = await PeasNFT.deploy("PlayEstates Arcadamy Station", "PEAS");    
    await peasNFT.unlock();

    const PlayEstatesTokenization = await ethers.getContractFactory("PlayEstatesTokenization");
    const pnft = await PlayEstatesTokenization.deploy("PlayEstates Real NFT", "PNFT", seller1.address, 100);   
    await pnft.deployed();
    await pnft.toggleTradingAllowed();

    const CustomNFTMock = await ethers.getContractFactory("CustomNFTMock");
    const customNFT = await CustomNFTMock.deploy("Custom NFT Token", "CUST");

    const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
    const pbrTokenMock = await PlayEstatesBrickToken.deploy("PlayEstates Bricks Token", "PBRT");

    const usdcMock = await PlayEstatesBrickToken.deploy("PlayEstates Fake USDC", "USDC");

    const NFTEngineV1 = await ethers.getContractFactory("NFTEngineV1");
    const nftEngine = await upgrades.deployProxy(
        NFTEngineV1, 
        [owner.address, treasury1.address], 
        { initializer: 'initialize' });
    await nftEngine.deployed();

    await nftEngine.setNFTContract(TokenTypes.membershipNFT, membershipNFT.address);
    await nftEngine.setNFTContract(TokenTypes.peasNFT, peasNFT.address);
    await nftEngine.setNFTContract(TokenTypes.pnftNFT, pnft.address);
    await nftEngine.setNFTContract(TokenTypes.customNFT, customNFT.address);

    await nftEngine.setPaymentContract(PayTypes.payUSDC, usdcMock.address);
    await nftEngine.setPaymentContract(PayTypes.payPBRT, pbrTokenMock.address);

    await pbrTokenMock.setMarketplaceEngine(nftEngine.address);
    await usdcMock.setMarketplaceEngine(nftEngine.address);

    return { 
      nftEngine, 
      membershipNFT, 
      peasNFT,
      pnft,
      customNFT, 
      pbrTokenMock, 
      usdcMock, 
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

    nftContracts.push(engineInfo.membershipNFT);
    nftContracts.push(engineInfo.peasNFT);
    nftContracts.push(engineInfo.pnft);
    nftContracts.push(engineInfo.customNFT);
  });

  it ("Should revert the set contracts", async () => {
    await expect(nftEngine.setNFTContract(
      TokenTypes.membershipNFT, ethers.constants.AddressZero
    )).to.be.reverted;  // Invalid nft contract address

    await expect(nftEngine.setNFTContract(
      10, engineInfo.membershipNFT.address
    )).to.be.reverted;  // Invalid nft type

    await expect(nftEngine.setPaymentContract(
      PayTypes.payPBRT,
      ethers.constants.AddressZero      
    )).to.be.reverted;  // Invalid payment token address
  });

  it ("Should mint various tokens for testing", async () => {
    // mint custom nft tokens
    let tokenOwner = engineInfo.seller1.address;    
    for (let tokenId = 1; tokenId <= 100; tokenId++) {
      await engineInfo.customNFT.mint(
        tokenOwner, tokenId
      );  
    }
    expect(await engineInfo.customNFT.balanceOf(tokenOwner)).to.be.equal(
      100,  "Failed to mint customNFT Token"
    );    

    // mint membership nft tokens
    let tx = await engineInfo.membershipNFT.mint(
      tokenOwner, nftTokenCount, 0
    );
    expect(await engineInfo.membershipNFT.balanceOf(tokenOwner)).to.be.equal(
      nftTokenCount,  "Failed to mint membershipNFT Token"
    );

    // mint peas nft tokens
    tx = await engineInfo.peasNFT.mint(
      tokenOwner, nftTokenCount
    );
    expect(await engineInfo.peasNFT.balanceOf(tokenOwner)).to.be.equal(
      nftTokenCount,  "Failed to mint peasNFT Token"
    );    

    // mint PBRT mock tokens to buyer 1
    tokenOwner = engineInfo.buyer1.address;    
    await engineInfo.pbrTokenMock.mint(
      tokenOwner, pbrtTokenBalance
    );

    // mint USDC mock tokens to buyer 1
    await engineInfo.usdcMock.mint(
      tokenOwner, pbrtTokenBalance
    );

    // mint PBRT mock tokens to buyer 2
    tokenOwner = engineInfo.buyer2.address;
    await engineInfo.pbrTokenMock.mint(
      tokenOwner, pbrtTokenBalance
    );

    // mint USDC mock tokens to buyer 2
    await engineInfo.usdcMock.mint(
      tokenOwner, pbrtTokenBalance
    );
  });

  it ("Should create a sale pricing 10 eth / usdc / pbrt for one nft token", async () => {
    let seller = engineInfo.seller1;
    let tokenId = 1;
    let tokenPrice = ethers.utils.parseEther("10");  // 100 eth / usdc / pbrt 

    for (let i = 0; i < nftContracts.length; i++) {
      await nftContracts[i].connect(seller).approve(
        nftEngine.address,
        tokenId
      );
  
      await expect(nftEngine.connect(seller).createSale(
        nftContracts[i].address,
        tokenId,
        payTypes[i],
        tokenPrice
      )).to.emit(nftEngine, "NFTTokenSaleCreated");
  
      let tokenSales = await nftEngine.getTokenInfosOnSale(nftContracts[i].address);
      await expect(tokenSales.length).to.be.equal(1, "Failed to create sales, invalid sales count");
  
      let tokenSale = await nftEngine.getTokenSaleInfo(nftContracts[i].address, tokenId);
      await expect(tokenSale.tokenId).to.be.equal(tokenId, "Failed to get token sale id");  
      await expect(tokenSale.payType).to.be.equal(payTypes[i], "Failed to get token sale paytype");  
    }
  });

  it ("Should revert the create sale because of several reasons", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let nftContract = engineInfo.membershipNFT;
    let tokenId = 2;
    let tokenPrice = 100;

    await expect(nftEngine.connect(buyer).createSale(
      nftContract.address,
      tokenId,
      PayTypes.payAll,
      tokenPrice
    )).to.be.reverted;  // onlyTokenOwner

    await expect(nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      PayTypes.payAll,
      tokenPrice
    )).to.be.reverted;  // onlyApprovedToken
    
    await nftContract.connect(seller).approve(
      nftEngine.address,
      tokenId
    );    

    await expect(nftEngine.connect(seller).createSale(
      nftContract.address,
      tokenId,
      PayTypes.payAll,
      0
    )).to.be.reverted;  // onlyValidPrice

    await expect(nftEngine.connect(seller).createSale(
      ethers.constants.AddressZero,
      tokenId,
      PayTypes.payAll,
      tokenPrice
    )).to.be.reverted;  // Unregistered nft contract
  });

  it ("Should buy nft with different payment", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let tokenId = 1;
    let tokenPrice = ethers.utils.parseEther("10");  // 100 eth / usdc / pbrt 

    for (let i = 0; i < nftContracts.length; i++) {
      switch (payTypes[i]) {
        case PayTypes.payEther: {
          await expect(nftEngine.connect(buyer).buyNFT(
            nftContracts[i].address,
            tokenId,
            payTypes[i], 
            {
              value: tokenPrice
            }
          )).to.be.emit(nftEngine, "NFTTokenSaleClosed");

          expect(await nftContracts[i].ownerOf(tokenId)).to.be.equal(buyer.address);
        }
          break;
        case PayTypes.payUSDC: {
          await engineInfo.usdcMock.connect(buyer).approve(
            nftEngine.address,
            tokenPrice
          );

          await expect(nftEngine.connect(buyer).buyNFT(
            nftContracts[i].address,
            tokenId,
            payTypes[i]
          )).to.be.emit(nftEngine, "NFTTokenSaleClosed");

          expect(await nftContracts[i].ownerOf(tokenId)).to.be.equal(buyer.address);
        }
          break;
        case PayTypes.payPBRT: {
          await engineInfo.pbrTokenMock.connect(buyer).approve(
            nftEngine.address,
            tokenPrice
          );

          await expect(nftEngine.connect(buyer).buyNFT(
            nftContracts[i].address,
            tokenId,
            payTypes[i]
          )).to.be.emit(nftEngine, "NFTTokenSaleClosed");

          expect(await nftContracts[i].ownerOf(tokenId)).to.be.equal(buyer.address);
        }
          break;
        case PayTypes.payFiat: {
          await expect(nftEngine.connect(buyer).buyNFT(
            nftContracts[i].address,
            tokenId,
            payTypes[i]
          )).to.be.revertedWith("Allowed only for backend");
        }
          break;
        default:
          break;
      }
    }
  });

  it ("Should revert the buying nft because of several bad parameters", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let tokenId = 10;

    await expect(nftEngine.connect(buyer).buyNFT(
      engineInfo.membershipNFT.address,
      tokenId,
      PayTypes.payEther
    )).to.be.reverted;  // onlySale

    tokenId = 1;
    await expect(nftEngine.connect(seller).buyNFT(
      engineInfo.customNFT.address,
      tokenId,
      PayTypes.payFiat
    )).to.be.reverted;  // onlyNotSaleSeller
  });

  it ("Should test the withdraw sale", async () => {
    let seller = engineInfo.seller1;
    let tokenId = 2;
    let tokenPrice = ethers.utils.parseEther("10");  // 100 eth / usdc / pbrt 

    await expect(nftEngine.connect(seller).createSale(
      nftContracts[0].address,
      tokenId,
      payTypes[0],
      tokenPrice,
    )).to.emit(nftEngine, 'NFTTokenSaleCreated'); 

    await expect(nftEngine.connect(seller).withdrawSale(
      nftContracts[0].address,
      tokenId
    )).to.emit(nftEngine, 'NFTTokenSaleWithdrawn'); 

    await expect(await nftContracts[0].ownerOf(tokenId)).to.be.equal(
      engineInfo.seller1.address, "Failed to withdrawSale"
    );
    
    await expect(nftEngine.connect(seller).withdrawSale(
      nftContracts[0].address,
      100
    )).to.be.reverted;  // onlySaleSeller
  });

  it ("Should create auctions pricing 10 ~ 50 eth / usdc / pbrt", async() => {
    let seller = engineInfo.seller1;
    let tokenId = 2;
    let minPrice = ethers.utils.parseEther("10"); 
    let buyNowPrice = ethers.utils.parseEther("50"); 
    let bidPeriod = 0;

    for (let i = 0; i < nftContracts.length; i++) {
      if (payTypes[i] == PayTypes.payFiat)
        continue;

      await nftContracts[i].connect(seller).approve(
        nftEngine.address,
        tokenId
      );
  
      await expect(nftEngine.connect(seller).createAuction(
        nftContracts[i].address,
        tokenId,
        payTypes[i],
        minPrice,
        buyNowPrice,
        bidPeriod
      )).to.emit(nftEngine, "NFTAuctionCreated");
  
      let tokenAuctions = await nftEngine.getTokenInfosOnAuction(nftContracts[i].address);
      await expect(tokenAuctions.length).to.be.equal(1, "Failed to create auction, invalid auctions count");
  
      let tokenAuction = await nftEngine.getTokenAuctionInfo(nftContracts[i].address, tokenId);
      await expect(tokenAuction.tokenId).to.be.equal(tokenId, "Failed to get token auction id");  
      await expect(tokenAuction.payType).to.be.equal(payTypes[i], "Failed to get token auction paytype");  
    }
  });

  it ("Should revert the create auction because of several reasons", async () => {
    let seller = engineInfo.seller1;
    let nftContract = engineInfo.membershipNFT;
    let minPrice = ethers.utils.parseEther("10"); 
    let buyNowPrice = ethers.utils.parseEther("50"); 
    
    await expect(nftEngine.connect(seller).createAuction(
      nftContracts[0].address,
      2,
      payTypes[0],
      minPrice,
      buyNowPrice,
      0
    )).to.be.reverted;  // NFTEngineSellerCant, already created

    await expect(nftEngine.connect(seller).createAuction(
      nftContracts[0].address,
      3,
      10,
      minPrice,
      buyNowPrice,
      0
    )).to.be.reverted;   // Unregistered payment contract
    
    await expect(nftEngine.connect(seller).createAuction(
      ethers.constants.AddressZero,
      3,
      payTypes[0],
      minPrice,
      buyNowPrice,
      0
    )).to.be.reverted;   // Unregistered nft contract

    await expect(nftEngine.connect(seller).createAuction(
      nftContracts[0].address,
      1,
      payTypes[0],
      minPrice,
      buyNowPrice,
      0
    )).to.be.reverted;  // NFTEngineNotTokenOwner

    await expect(nftEngine.connect(seller).createAuction(
      nftContracts[0].address,
      3,
      payTypes[0],
      buyNowPrice,
      minPrice,
      0
    )).to.be.reverted;  // NFTEngineInvalidMinPrice
  });

  it ("Should make bid from auctions list", async () => {
    let buyer = engineInfo.buyer1;
    let tokenId = 2;
    let tokenPrice = ethers.utils.parseEther("11"); 

    for (let i = 0; i < nftContracts.length; i++) {
      switch (payTypes[i]) {
        case PayTypes.payEther: {
          await expect(nftEngine.connect(buyer).makeBid(
            nftContracts[i].address,
            tokenId,
            payTypes[i], 
            tokenPrice,
            {
              value: tokenPrice
            }
          )).to.be.emit(nftEngine, "NFTAuctionBidMade");
        }
          break;
        case PayTypes.payUSDC: {
          await engineInfo.usdcMock.connect(buyer).approve(
            nftEngine.address,
            tokenPrice
          );

          await expect(nftEngine.connect(buyer).makeBid(
            nftContracts[i].address,
            tokenId,
            payTypes[i],
            tokenPrice
          )).to.be.emit(nftEngine, "NFTAuctionBidMade");
        }
          break;
        case PayTypes.payPBRT: {
          await engineInfo.pbrTokenMock.connect(buyer).approve(
            nftEngine.address,
            tokenPrice
          );

          await expect(nftEngine.connect(buyer).makeBid(
            nftContracts[i].address,
            tokenId,
            payTypes[i],
            tokenPrice
          )).to.be.emit(nftEngine, "NFTAuctionBidMade");
        }
          break;
        case PayTypes.payFiat: {
          await expect(nftEngine.connect(buyer).makeBid(
            nftContracts[i].address,
            tokenId,
            payTypes[i],
            tokenPrice
          )).to.be.reverted;
        }
          break;
        default:
          break;
      }
    }
  });

  it ("Should make bid with buyNowPrice for completion auction", async () => {
    let buyer = engineInfo.buyer2;
    let tokenId = 2;
    let tokenPrice = ethers.utils.parseEther("50"); 

    for (let i = 0; i < 2; i++) {
      switch (payTypes[i]) {
        case PayTypes.payEther: {
          await expect(nftEngine.connect(buyer).makeBid(
            nftContracts[i].address,
            tokenId,
            payTypes[i], 
            tokenPrice,
            {
              value: tokenPrice
            }
          )).to.be.emit(nftEngine, "NFTAuctionPaid");
        }
          break;
        case PayTypes.payUSDC: {
          await engineInfo.usdcMock.connect(buyer).approve(
            nftEngine.address,
            tokenPrice
          );

          await expect(nftEngine.connect(buyer).makeBid(
            nftContracts[i].address,
            tokenId,
            payTypes[i],
            tokenPrice
          )).to.be.emit(nftEngine, "NFTAuctionPaid");
        }
          break;
        default:
          break;
      }
    }
  });

  it ("Should revert the makebid becase of some bad parameters", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer2;
    let tokenId = 2;
    let invalidPrice = ethers.utils.parseEther("1");
    let bidPrice = ethers.utils.parseEther("15");
    
    await expect(nftEngine.connect(seller).makeBid(
      nftContracts[2].address,
      tokenId,
      payTypes[2],
      bidPrice,
      {value: bidPrice}
    )).to.be.reverted;  // onlyNotAuctionSeller

    await expect(nftEngine.connect(buyer).makeBid(
      nftContracts[2].address,
      tokenId,
      payTypes[2],
      bidPrice
    )).to.be.reverted;  // Not allowanced erc20

    await engineInfo.pbrTokenMock.connect(buyer).approve(
      nftEngine.address,
      bidPrice
    );

    await expect(nftEngine.connect(buyer).makeBid(
      nftContracts[2].address,
      tokenId,
      payTypes[2],
      invalidPrice
    )).to.be.revertedWith("Insufficient funds to bid");  // "Insufficient funds to bid"

    await increaseTime(7 * oneDaySeconds);

    await expect(nftEngine.connect(buyer).makeBid(
      nftContracts[2].address,
      tokenId,
      payTypes[2],
      bidPrice
    )).to.be.reverted;  // NFTEngineAuctionFinished
  });  

  it ("Should test settle auction", async () => {
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let tokenId = 3;
    let minPrice = ethers.utils.parseEther("1");
    let buyNowPrice = ethers.utils.parseEther("15");
    let bidPrice = ethers.utils.parseEther("10");

    await expect(nftEngine.connect(seller).settleAuction(
      nftContracts[0].address,
      tokenId
    )).to.be.reverted;    // NFTEngineNotAuctionToken

    await nftContracts[0].connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await nftEngine.connect(seller).createAuction(
      nftContracts[0].address,
      tokenId,
      payTypes[0],
      minPrice,
      buyNowPrice,
      0
    );

    await expect(nftEngine.connect(seller).settleAuction(
      nftContracts[0].address,
      tokenId
    )).to.be.reverted;    // ERC721Psi: transfer of token that is not own (1st makeBid => NFT transfer to engine)

    await nftEngine.connect(buyer).makeBid(
      nftContracts[0].address,
      tokenId,
      payTypes[0],
      bidPrice, {
        value: bidPrice
      }
    );

    await expect(nftEngine.connect(seller).settleAuction(
      nftContracts[0].address,
      tokenId
    )).to.emit(nftEngine, 'NFTAuctionSettled');
  });   

  it ("Should test withdraw auction", async () => {
    // create new auction again for withdraw testing
    let seller = engineInfo.seller1;
    let buyer = engineInfo.buyer1;
    let tokenId = 4;
    let minPrice = ethers.utils.parseEther("1");
    let buyNowPrice = ethers.utils.parseEther("15");
    let bidPrice = ethers.utils.parseEther("10");

    await nftContracts[0].connect(seller).approve(
      nftEngine.address,
      tokenId
    );

    await nftEngine.connect(seller).createAuction(
      nftContracts[0].address,
      tokenId,
      payTypes[0],
      minPrice,
      buyNowPrice,
      0
    );

    // withdraw auction by seller
    await expect(nftEngine.connect(seller).withdrawAuction(
      nftContracts[0].address,
      tokenId
    )).to.be.emit(nftEngine, 'NFTAuctionWithdrawn');

    await expect(await nftContracts[0].ownerOf(tokenId)).to.be.equal(
      seller.address, "Failed to withdrawAuction action"
    );
  });

  // it ("Should test takehighestbid auction", async () => {
  //   // create new auction again for withdraw testing
  //   const nftContract = engineInfo.membershipNFT;
  //   const tokenId = 12;
  //   const minPrice = ethers.utils.parseEther("0.1");
  //   const buyNowPrice = ethers.utils.parseEther("1");
  //   const ethAmount = ethers.utils.parseEther("0.5");
  //   const seller = engineInfo.seller1;

  //   await nftContract.connect(seller).approve(
  //     nftEngine.address,
  //     tokenId
  //   );

  //   await nftEngine.connect(seller).createAuction(
  //     nftContract.address,
  //     tokenId,
  //     ethers.constants.AddressZero,
  //     minPrice,
  //     buyNowPrice,
  //     oneDaySeconds,
  //     emptyFeeRecipients,
  //     emptyFeePercentages
  //   );  

  //   await expect(nftEngine.connect(seller).takeHighestBid(
  //     nftContract.address,
  //     tokenId
  //   )).to.be.reverted;  // NFTEngineDidNotBid

  //   await nftEngine.connect(engineInfo.buyer1).makeBid(
  //     nftContract.address,
  //     tokenId,
  //     ethers.constants.AddressZero,
  //     0,
  //     {value: ethAmount}
  //   );

  //   await expect(nftEngine.connect(seller).takeHighestBid(
  //     nftContract.address,
  //     tokenId
  //   )).to.emit(nftEngine, 'NFTAuctionHighestBidTaken');

  //   await expect(await nftContract.ownerOf(tokenId)).to.be.equal(
  //     engineInfo.buyer1.address, "Failed to takeHighestBid action"
  //   );
  // });

  // it ("Should revert the takehighestbid because of several reasons", async () => {
  //   // create new auction again for withdraw testing
  //   const nftContract = engineInfo.membershipNFT;
  //   const tokenId = 13;
  //   const seller = engineInfo.seller1;
  //   const buyer = engineInfo.buyer1;

  //   await expect(nftEngine.connect(buyer).takeHighestBid(
  //     nftContract.address,
  //     tokenId
  //   )).to.be.reverted;  // onlyAuctionSeller

  //   await expect(nftEngine.connect(seller).takeHighestBid(
  //     nftContract.address,
  //     tokenId
  //   )).to.be.reverted;  // onlyAuctionSeller (not auctioning now)
  // });

  // it ("Should test remove many sales and auctions for checking gas", async () => {
  //   // create new auction again for withdraw testing
  //   const nftContract = engineInfo.membershipNFT;    
  //   const minPrice = 1;
  //   const buyNowPrice = 10;
  //   const seller = engineInfo.seller1;

  //   await engineInfo.membershipNFT.mint(
  //     seller.address, nftTokenCount, 0
  //   );

  //   for (let i = 0; i < nftTokenCount; i++) {
  //     const tokenId = i + nftTokenCount;
  //     await nftContract.connect(seller).approve(
  //       nftEngine.address,  
  //       tokenId      
  //     );
  
  //     await nftEngine.connect(seller).createSale(
  //       nftContract.address,
  //       tokenId,
  //       engineInfo.pbrTokenMock.address,
  //       buyNowPrice,
  //       emptyFeeRecipients,
  //       emptyFeePercentages
  //     );
  //   }
    
  //   for (let i = 0; i < nftTokenCount; i++) {
  //     const tokenId = i + nftTokenCount;
  //     await nftEngine.connect(seller).withdrawSale(
  //       nftContract.address,
  //       tokenId
  //     );
  //   }

  //   for (let i = 0; i < nftTokenCount; i++) {
  //     const tokenId = i + nftTokenCount;
  //     await nftContract.connect(seller).approve(
  //       nftEngine.address,  
  //       tokenId      
  //     );
  
  //     await nftEngine.connect(seller).createAuction(
  //       nftContract.address,
  //       tokenId,
  //       engineInfo.pbrTokenMock.address,
  //       minPrice,
  //       buyNowPrice,
  //       0,
  //       emptyFeeRecipients,
  //       emptyFeePercentages
  //     );
  //   }
    
  //   for (let i = 0; i < nftTokenCount; i++) {
  //     const tokenId = i + nftTokenCount;
  //     await nftEngine.connect(seller).withdrawAuction(
  //       nftContract.address,
  //       tokenId
  //     );
  //   }    
  // });

  async function getERC20Balance(wallet) {
    const balance = await engineInfo.pbrTokenMock.balanceOf(wallet);
    return ethers.utils.formatEther(balance);
  }

  async function getEtherBalance(wallet) {
    const balance = await ethers.provider.getBalance(wallet);
    return ethers.utils.formatEther(balance);
  }
  
});
