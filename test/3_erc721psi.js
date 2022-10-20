const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, network, upgrades } = require("hardhat");
const { nftTokenCount } = require("./utils");

describe("ERC721Psi Contract", function () {
  let engineInfo;
  let psiNFT;

  async function deployBaseContracts() {
    const [owner, minter, user] = await ethers.getSigners();

    const ERC721Psi = await ethers.getContractFactory("ERC721Psi");
    const psiNFT = await ERC721Psi.deploy("ERC721Psi Test Token", "PNFT");    

    return { 
      psiNFT, 
      owner, 
      minter,
      user
    };
  }

  before('Set deployed contract variable', async () => {
    engineInfo = await deployBaseContracts();
    psiNFT = engineInfo.psiNFT;
  });

  it ("Should test external functions", async () => {
    const nftId = 1;

    await expect(psiNFT.tokenURI(nftId)).to.be.reverted;  // not exist token id

    await expect(await psiNFT.totalSupply()).to.be.equal(0);

    await expect(await psiNFT.symbol()).to.be.equal("PNFT");

    await expect(psiNFT.tokenByIndex(0)).to.be.reverted;

    await expect(psiNFT.tokenOfOwnerByIndex(engineInfo.minter.address, 0)).to.be.reverted;
  });

});
