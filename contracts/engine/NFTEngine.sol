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

    address private _treasury;

    uint256 public constant feeToTreasury = 5;

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

    modifier onlySale(uint256 tokenId) {
        require(_nftSells[tokenId].seller != address(0), 
            "Not sale token");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(msg.sender == IERC721(_nftContract).ownerOf(tokenId),
            "Sender isn't owner of NFT");
        _;
    }

    modifier onlyApprovedToken(uint256 tokenId) {
        require(address(this) == IERC721(_nftContract).getApproved(tokenId),
            "NFT is not approved by Marketplace");
        _;
    }

    modifier onlyNotTokenOwner(uint256 tokenId) {
        require(msg.sender != IERC721(_nftContract).ownerOf(tokenId),
            "Sender is owner of NFT");
        _;
    }

    constructor(address creator, address nftContract, address treasury) {
        require(creator != address(0), "Invalid marketplace owner");
        require(nftContract != address(0), "Invalid nft contract");
        require(treasury != address(0), "Invalid treasury address");
        
        _nftContract = nftContract;
        _treasury = treasury;

        defaultBidIncRate = 100;
        minSettableIncRate = 86400;
        maxMinPriceRate = 100;
        defaultAuctionBidPeriod = 8000;

        transferOwnership(creator);
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

    function changeTreasury(address newTreasury)
    external onlyOwner {
        require(newTreasury != address(0), "Invalid new treasury");
        _treasury = newTreasury;
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
    onlyApprovedToken(tokenId)
    onlyValidPrice(sellPrice) 
    onlyNotSale(tokenId) {

        _nftIdsForSell.push(tokenId);

        _nftSells[tokenId].erc20Token = erc20Token;
        _nftSells[tokenId].seller = msg.sender;
        _nftSells[tokenId].price = sellPrice;        
        _nftSells[tokenId].feeRecipients = feeRecipients;
        _nftSells[tokenId].feeRates = feeRates;

        emit NFTTokenSaleCreated(
            _nftContract,
            tokenId, 
            msg.sender,
            erc20Token,
            sellPrice
        );
    }

    function cancelSale(uint256 tokenId)
    external
    onlyTokenOwner(tokenId)
    onlySale(tokenId) {
        delete _nftSells[tokenId];
        removeNftIdFromSells(tokenId);

        emit NFTTokenSaleCanceled(
            _nftContract, 
            tokenId
        );    
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

    function buyNFT(uint256 tokenId) 
    external 
    payable
    onlySale(tokenId)
    onlyNotTokenOwner(tokenId) {
        require(msg.sender != address(0), "Invalid nft buyer");
        uint256 amount = _nftSells[tokenId].price;
        uint256 toTreasury = amount * feeToTreasury / 100;
        uint256 toSeller = amount - toTreasury;
        address seller = _nftSells[tokenId].seller;
        
        if (_nftSells[tokenId].erc20Token == address(0)) {
            /// paying with ether
            require(msg.value >= amount, "Insufficient Ether");

            (bool bSent, ) = payable(seller).call{
                value: toSeller
            }("");
            if (!bSent) {
                revert("Failed sending ether to seller");
            }

            (bSent, ) = payable(_treasury).call{
                value: toTreasury
            }("");
            if (!bSent) {
                revert("Failed sending ether to treasury");
            }
        }
        else {
            /// paying with erc20 token

            if (!IERC20(_nftSells[tokenId].erc20Token).transferFrom(
                msg.sender, seller, toSeller)) {
                revert("Failed sending erc20 to seller");
            }

            if (!IERC20(_nftSells[tokenId].erc20Token).transferFrom(
                msg.sender, _treasury, toTreasury)) {
                revert("Failed sending erc20 to treasury");
            }
        }    

        delete _nftSells[tokenId];
        removeNftIdFromSells(tokenId);

        IERC721(_nftContract).safeTransferFrom(seller, msg.sender, tokenId);

        emit NFTTokenSaleClosed(
            _nftContract, 
            tokenId, 
            msg.sender
        );    
    }

    function mintNFT(uint256 tokenId) external {

    }
    
    function nftOwner(uint256 tokenId) 
    external 
    view returns (address) {
        return IERC721(_nftContract).ownerOf(tokenId);       
    }
}