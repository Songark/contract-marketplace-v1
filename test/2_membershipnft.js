const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");
const { nftTokenCount } = require("./utils");

describe("PlayEstates Membership NFT Token", function () {
  let engineInfo;
  let mnftToken;

  async function deployBaseContracts() {
    const [owner, minter, user] = await ethers.getSigners();

    const MembershipNFT = await ethers.getContractFactory("MembershipNFT");
    const membershipNFT = await MembershipNFT.deploy("Genesis Owner Key", "MNFT");    

    return { 
      membershipNFT, 
      owner, 
      minter,
      user
    };
  }

  before('Set deployed contract variable', async () => {
    engineInfo = await deployBaseContracts();
    mnftToken = engineInfo.membershipNFT;
  });

  it ("Should test mint nfts", async () => {
    await mnftToken.mint(
      engineInfo.minter.address, 
      nftTokenCount, 
      0
    );
    await expect(await mnftToken.balanceOf(engineInfo.minter.address)).to.be.equal(
      nftTokenCount,  "Failed to mint membershipNFT Token"
    ); 
  });

  it ("Should test burn nfts", async () => {
    const nftId = 1;
    await expect(mnftToken.burn(nftId)).to.be.reverted;

    await expect(mnftToken.connect(engineInfo.minter).burn(
      nftId
    )).to.emit(mnftToken, 'Burn');

    await expect(await mnftToken.balanceOf(engineInfo.minter.address)).to.be.equal(
      nftTokenCount - 1,  "Failed to burn membershipNFT Token"
    ); 
  });

  it ("Should test process uri", async () => {
    const nftId = 2;
    await mnftToken.setImageURI(
      "https://playestates.mypinata.cloud/ipfs/QmfRdaYxMmvxrBbEcp3yVz4TUwnQJmTmPnqc1tQhfKWoKF/"
    );

    await mnftToken.setAnimationURI(
      "https://playestates.mypinata.cloud/ipfs/Qmb1krM5cm2GesmnX4MgTGdqiiPKU9Z5eviKLx5tqat7VV/"
    );

    await expect(mnftToken.tokenURI(0)).to.be.reverted;

    await mnftToken.tokenURI(nftId);

    await mnftToken.totalSupply();

    await mnftToken.getMintedPerType(0);

    await mnftToken.connect(engineInfo.minter).setApprovalForAll(
      engineInfo.user.address,
      true
    );

    await mnftToken.isApprovedForAll(
      engineInfo.minter.address,
      engineInfo.user.address
    );

    await mnftToken.connect(engineInfo.user).transferFrom(
      engineInfo.minter.address,
      engineInfo.owner.address,
      2
    );

    await expect(mnftToken.balanceOf(ethers.constants.AddressZero)).to.be.reverted; // 
  });

});
