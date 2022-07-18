const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');


describe("NFTEngine", function () {
  let engineInfo;
  let nftEngine;

  async function deployTwoMarketplaces() {
    const [owner, seller, buyer, treasury] = await ethers.getSigners();

    const ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    const erc721Mock = await ERC721Mock.deploy("Test NFT Token", "TNT");

    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const erc20Mock = await ERC20Mock.deploy("Test ERC20 Token", "TET");

    const NFTEngineFactory = await ethers.getContractFactory("NFTEngineFactory");
    const nftEngineFactory = await NFTEngineFactory.deploy();

    return { nftEngineFactory, erc721Mock, erc20Mock, owner, seller, buyer, treasury };
  }

  before('Create loader', async () => {
    engineInfo = await loadFixture(deployTwoMarketplaces);
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

    console.log("marketplace:", nftEngine.address);    
  });

  it ("Should initialize NFT Token and ERC20 Token", async () => {
    const tokenId = 1;
    await engineInfo.erc721Mock.mint(engineInfo.seller.address, tokenId);
    await expect(await engineInfo.erc721Mock.ownerOf(tokenId)).to.be.equal(
      engineInfo.seller.address,  "Failed to mint NFT"
    );

    const tokenBalance = 10000;
    await engineInfo.erc20Mock.mint(engineInfo.buyer.address, tokenBalance);
    await expect(await engineInfo.erc20Mock.balanceOf(engineInfo.buyer.address))
    .to.be.equal(
      tokenBalance,  "Failed to mint ERC20"
    );
  });

  it ("Should create a sale with NFT token", async () => {
    const tokenId = 1;
    const tokenPrice = 1000;
    await nftEngine.connect(engineInfo.seller).createSale(
      tokenId,
      engineInfo.erc20Mock.address,
      tokenPrice,
      [],
      []
    );

    let nfts = await nftEngine.getTokensOnSale();
    const nftInfo = await nftEngine.getTokenSaleInfo(nfts[0]);
    console.log(nftInfo);
  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
