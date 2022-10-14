const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");
const { pbrtTokenBalance } = require("./utils");

describe("PlayEstates Bricks Token", function () {
  let engineInfo;
  let bricksToken;

  async function deployBaseContracts() {
    const [owner, gameengine, marketplace, minter, user1, user2] = await ethers.getSigners();

    const PlayEstatesBrickToken = await ethers.getContractFactory("PlayEstatesBrickToken");
    const pbrToken = await PlayEstatesBrickToken.deploy("PlayEstates Bricks Token", "PBRT");

    await pbrToken.setMarketplaceEngine(marketplace.address);
    await pbrToken.setGameEngine(gameengine.address);    

    return { 
      pbrToken, 
      owner, 
      gameengine, 
      marketplace, 
      minter,
      user1,
      user2
    };
  }

  before('Set Roles in Bricks Token Contract', async () => {
    engineInfo = await deployBaseContracts();
    bricksToken = engineInfo.pbrToken;
  });

  it ("Should test set / clear role", async () => {
    await expect(bricksToken.setMintRole(
      engineInfo.minter.address
    )).to.emit(bricksToken, 'RoleGranted').withArgs(
      ethers.utils.formatBytes32String("MINTER_ROLE"),
      engineInfo.minter.address,
      engineInfo.owner.address
    );

    await expect(bricksToken.clearMintRole(
      engineInfo.minter.address
    )).to.emit(bricksToken, 'RoleRevoked').withArgs(
      ethers.utils.formatBytes32String("MINTER_ROLE"),
      engineInfo.minter.address,
      engineInfo.owner.address
    );
  });

  it ("Should test mint tokens", async () => {
    await expect(bricksToken.mint(
      engineInfo.user1.address,
      pbrtTokenBalance
    )).to.emit(bricksToken, 'Transfer').withArgs(
      ethers.constants.AddressZero,
      engineInfo.user1.address,
      pbrtTokenBalance
    );

    await expect(bricksToken.connect(engineInfo.minter).mint(
      engineInfo.user2.address,
      pbrtTokenBalance
    )).to.be.reverted;

    await expect(bricksToken.setMintRole(
      engineInfo.minter.address
    )).to.emit(bricksToken, 'RoleGranted').withArgs(
      ethers.utils.formatBytes32String("MINTER_ROLE"),
      engineInfo.minter.address,
      engineInfo.owner.address
    );

    await expect(bricksToken.connect(engineInfo.minter).mint(
      engineInfo.user2.address,
      pbrtTokenBalance
    )).to.emit(bricksToken, 'Transfer').withArgs(
      ethers.constants.AddressZero,
      engineInfo.user2.address,
      pbrtTokenBalance
    );
  });

  it ("Should test locking tokens", async () => {
    await expect(bricksToken.connect(engineInfo.user1).approve(
      engineInfo.gameengine.address,
      10
    )).to.emit(bricksToken, 'Approval');

    await expect(bricksToken.connect(engineInfo.gameengine).transferFrom(
      engineInfo.user1.address,
      engineInfo.user2.address,
      10
    )).to.emit(bricksToken, 'Transfer');
    
    await expect(bricksToken.connect(engineInfo.user1).transfer(
      engineInfo.user2.address,
      10
    )).to.be.reverted;

    await bricksToken.setLock(false);

    await expect(bricksToken.connect(engineInfo.user1).transfer(
      engineInfo.user2.address,
      10
    )).to.emit(bricksToken, 'Transfer');
  });
});
