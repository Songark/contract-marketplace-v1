//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../library/LTypes.sol";
import "../interface/INFTEngine.sol";

contract NFTEngine is Ownable, INFTEngine {

    address private immutable _nftContract;

    mapping(uint256 => LTypes.AuctionNFT) private _nftAuctions;

    uint256[] private _nftIdsForAction;

    mapping(uint256 => LTypes.SellNFT) private _nftSells;

    uint256[] private _nftIdsForSell;

    mapping(uint256 => LTypes.MintNFT) private _nftMints;

    uint32 public immutable defaultBidIncRate;

    uint32 public immutable minSettableIncRate;

    uint32 public immutable maxMinPriceRate;

    uint32 public immutable defaultAuctionBidPeriod;

    modifier onlyValidPrice(uint256 price) {
        require(price > 0, "Price cannot be 0");
        _;
    }

    modifier onlyNotSale(uint256 tokenId) {
        require(_nftSells[tokenId].seller == address(0), 
            "Not allowed saling token");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == IERC721(_nftContract).ownerOf(tokenId),
            "Sender isn't owner of NFT");
        _;
    }

    constructor(address nftContract) {
        require(nftContract != address(0), "Invalid nft contract");
        
        _nftContract = nftContract;

        defaultBidIncRate = 100;
        minSettableIncRate = 86400;
        maxMinPriceRate = 100;
        defaultAuctionBidPeriod = 8000;
    }

    function removeNftIdFromSells(uint256 nftId) 
    internal {
        for (uint256 i = 0; i < _nftIdsForSell.length; i++) {
            if (_nftIdsForSell[i] == nftId) {
                for (uint256 j = i; j < _nftIdsForSell.length - 1; j++) {
                    _nftIdsForSell[j] = _nftIdsForSell[j + 1];
                }
                _nftIdsForSell.pop();
            }
        }
        delete _nftSells[nftId];
    }

    function removeNftIdFromAuctions(uint256 nftId) 
    internal {
        for (uint256 i = 0; i < _nftIdsForAction.length; i++) {
            if (_nftIdsForAction[i] == nftId) {
                for (uint256 j = i; j < _nftIdsForAction.length - 1; j++) {
                    _nftIdsForAction[j] = _nftIdsForAction[j + 1];
                }
                _nftIdsForAction.pop();
            }
        }
        delete _nftAuctions[nftId];
    }

    function createAuction() external {

    }

    function calcAuction() external {

    }

    function claimAuction() external {

    }

    function makeBid() external {

    }

    function withdrawBid() external {
        
    }

    function createSale(
        uint256 tokenId,
        address erc20Token,
        uint128 sellPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external 
    onlyTokenOwner(tokenId)
    onlyValidPrice(sellPrice) 
    onlyNotSale(tokenId) {

        _nftIdsForSell.push(tokenId);

        _nftSells[tokenId].erc20Token = erc20Token;
        _nftSells[tokenId].seller = msg.sender;
        _nftSells[tokenId].price = sellPrice;        
        _nftSells[tokenId].feeRecipients = feeRecipients;
        _nftSells[tokenId].feeRates = feeRates;
    }

    function getTokensOnSale() 
    external 
    view returns (uint256[] memory) {
        return _nftIdsForSell;
    }

    function getTokenSaleInfo(uint256 tokenId) 
    external 
    view returns (LTypes.SellNFT memory) {
        return _nftSells[tokenId];
    }

    function buyNFT(uint256 tokenId) external {

    }

    function sellNFT(uint256 tokenId) external {

    }

    function nftOwner(uint256 tokenId) external {

    }
}