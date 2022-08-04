//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../library/LTypes.sol";
import "../interface/INFTEngine.sol";
import "../interface/IERC721Mock.sol";

contract NFTEngine is Initializable, OwnableUpgradeable, INFTEngine {

    address private _nftContract;

    address private _treasury;

    uint256 public constant feeToTreasury = 5;

    mapping(uint256 => LTypes.AuctionNFT) private _nftAuctions;

    uint256[] private _nftIdsForAction;

    mapping(uint256 => LTypes.SellNFT) private _nftSells;

    uint256[] private _nftIdsForSell;

    mapping(uint256 => LTypes.MintNFT) private _nftMints;

    uint32 public constant defaultBidIncRate = 100;

    uint32 public constant minSettableIncRate = 86400;

    uint32 public constant maxMinPriceRate = 100;

    uint32 public constant defaultAuctionBidPeriod = 8000;

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

    modifier minPriceNotExceedLimit(
        uint128 buyNowPrice, uint128 minPrice 
    ) {
        require(
            buyNowPrice == 0 ||
                _getPortionOfBid(buyNowPrice, maxMinPriceRate) >=
                minPrice,
            "minPrice > 80% of buyNowPrice"
        );
        _;
    }

    modifier checkSizeRecipientsAndRates(
        uint256 recipients, uint256 rates
    ) {
        require(
            recipients == rates,
            "Recipients != Rates"
        );
        _;
    }

    modifier checkFeeRatesLessThanMaximum(
        uint32[] memory feeRates
    ) {
        uint32 totalPercent;
        for (uint256 i = 0; i < feeRates.length; i++) {
            totalPercent = totalPercent + feeRates[i];
        }
        require(totalPercent <= 10000, "Fee Rates exceed maximum, 10000");
        _;
    }

    modifier auctionOngoing(uint256 tokenId) {
        require(
            _isAuctionOngoing(tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier onlyApplicableBuyer(uint256 tokenId) {
        require(
            !_isWhitelistedSale(tokenId) ||
                _nftAuctions[tokenId].whitelistedBuyer == msg.sender,
            "Only the whitelisted buyer"
        );
        _;
    }

    function initialize(address creator, address nftContract, address treasury) 
    initializer public {
        require(creator != address(0), "Invalid marketplace owner");
        require(nftContract != address(0), "Invalid nft contract");
        require(treasury != address(0), "Invalid treasury address");
        
        __Ownable_init();

        _nftContract = nftContract;
        _treasury = treasury;
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

    function createAuction(
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external {
        
        _setupAuction(
            tokenId,
            erc20Token,
            minPrice,
            buyNowPrice,
            feeRecipients,
            feeRates
        );

        emit NFTAuctionCreated(
            _nftContract,
            tokenId,
            msg.sender,
            erc20Token,
            minPrice,
            buyNowPrice,
            _getAuctionBidPeriod(tokenId),
            _getBidIncreasePercentage(tokenId),
            feeRecipients,
            feeRates
        );

        _updateOngoingAuction(tokenId);
    }

    function calcAuction() external {

    }

    function claimAuction() external {

    }

    function makeBid(
        uint256 tokenId,
        address erc20Token,
        uint128 amount
    ) 
    external 
    payable 
    auctionOngoing(tokenId) 
    onlyApplicableBuyer(tokenId) {
        
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

    function mintNFT(address erc20, uint256 price, uint256 royalty, string memory uri) 
    external {        
        IERC721Mock(_nftContract).safeMint(msg.sender, uri);
    }
    
    function nftOwner(uint256 tokenId) 
    external 
    view returns (address) {
        return IERC721(_nftContract).ownerOf(tokenId);       
    }


    function _setupAuction(
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    )
    internal
    minPriceNotExceedLimit(buyNowPrice, minPrice)
    checkSizeRecipientsAndRates(
        feeRecipients.length, feeRates.length
    )
    checkFeeRatesLessThanMaximum(feeRates)
    {
        if (erc20Token != address(0)) {
            _nftAuctions[tokenId].erc20Token = erc20Token;
        }
        _nftAuctions[tokenId].feeRecipients = feeRecipients;
        _nftAuctions[tokenId].feeRates = feeRates;
        _nftAuctions[tokenId].buyNowPrice = buyNowPrice;
        _nftAuctions[tokenId].minPrice = minPrice;
        _nftAuctions[tokenId].seller = msg.sender;
    }

    function _isAuctionOngoing(uint256 tokenId)
    internal
    view returns (bool)
    {
        // if the Auction's endTime is set to 0, the auction is technically on-going, however
        // the minimum bid price (minPrice) has not yet been met.
        return (_nftAuctions[tokenId].endTime == 0 ||
            block.timestamp < _nftAuctions[tokenId].endTime);
    }

    function _isAlreadyBidMade(uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_nftAuctions[tokenId].highestBid > 0);
    }

    function _isMinimumBidMade(uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 minPrice = _nftAuctions[tokenId].minPrice;
        return ( minPrice > 0 &&
            (_nftAuctions[tokenId].highestBid >= minPrice));
    }

    function _isBuyNowPriceMet(uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 buyNowPrice = _nftAuctions[tokenId].buyNowPrice;
        return (buyNowPrice > 0 &&
            _nftAuctions[tokenId].highestBid >= buyNowPrice);
    }

    /*
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(uint256 totalBid, uint256 rate)
    internal
    pure returns (uint256)
    {
        return (totalBid * rate) / 10000;
    }

    function _getAuctionBidPeriod(uint256 _tokenId)
    internal
    view
    returns (uint32)
    {
        uint32 auctionBidPeriod = _nftAuctions[_tokenId].bidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    function _getNftRecipient(uint256 tokenId)
    internal
    view
    returns (address)
    {
        address nftRecipient = _nftAuctions[tokenId].recipient;

        if (nftRecipient == address(0)) {
            return _nftAuctions[tokenId].highestBidder;
        } else {
            return nftRecipient;
        }
    }

    function _getBidIncreasePercentage(
        uint256 _tokenId
    ) 
    internal 
    view returns (uint32) {
        uint32 bidIncreasePercentage = _nftAuctions[_tokenId].bidIncRate;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncRate;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _updateOngoingAuction(uint256 tokenId) 
    internal {
        if (_isBuyNowPriceMet(tokenId)) {
            _transferNftToAuctionContract(tokenId);
            _transferNftAndPaySeller(tokenId);
            return;
        }
        //min price not set, nft not up for auction yet
        if (_isMinimumBidMade(tokenId)) {
            _transferNftToAuctionContract(tokenId);
            _updateAuctionEnd(tokenId);
        }
    }

    function _transferNftToAuctionContract(uint256 tokenId) internal {
        address _nftSeller = _nftAuctions[tokenId].seller;

        if (IERC721(_nftContract).ownerOf(tokenId) == _nftSeller) {
            IERC721(_nftContract).transferFrom(
                _nftSeller,
                address(this),
                tokenId
            );
            require(
                IERC721(_nftContract).ownerOf(tokenId) == address(this),
                "nft transfer failed"
            );
        } else {
            require(
                IERC721(_nftContract).ownerOf(tokenId) == address(this),
                "Seller doesn't own NFT"
            );
        }
    }

    function _transferNftAndPaySeller(uint256 tokenId) internal {
        address nftSeller = _nftAuctions[tokenId].seller;
        address nftHighestBidder = _nftAuctions[tokenId].highestBidder;
        address nftRecipient = _getNftRecipient(tokenId);
        uint128 nftHighestBid = _nftAuctions[tokenId].highestBid;
        _resetBids(tokenId);

        _payFeesAndSeller(
            tokenId,
            nftSeller,
            nftHighestBid
        );
        IERC721(_nftContract).transferFrom(
            address(this),
            nftRecipient,
            tokenId
        );

        _resetAuction(tokenId);
        emit NFTAuctionPaid(
            _nftContract,
            tokenId,
            nftSeller,
            nftHighestBid,
            nftHighestBidder,
            nftRecipient
        );
    }

    function _payFeesAndSeller(
        uint256 tokenId,
        address nftSeller,
        uint256 highestBid
    ) internal {
        uint256 feesPaid;
        for (uint256 i = 0; i < _nftAuctions[tokenId] .feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(
                highestBid,
                _nftAuctions[tokenId].feeRates[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                tokenId,
                _nftAuctions[tokenId].feeRecipients[i],
                fee
            );
        }
        _payout(
            tokenId,
            nftSeller,
            (highestBid - feesPaid)
        );
    }

    function _payout(
        uint256 tokenId,
        address recipient,
        uint256 amount
    ) internal {
        address auctionERC20Token = _nftAuctions[tokenId].erc20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transfer(recipient, amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(recipient).call{
                value: amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
            }
        }
    }

    function _isERC20Auction(address _auctionERC20Token)
    internal
    pure
    returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    function _updateAuctionEnd(uint256 tokenId) internal {
        //the auction end is always set to now + the bid period
        _nftAuctions[tokenId].endTime =
            _getAuctionBidPeriod(tokenId) + uint64(block.timestamp);

        emit NFTAuctionUpdated(
            _nftContract,
            tokenId,
            _nftAuctions[tokenId].endTime
        );
    }

    function _resetAuction(uint256 tokenId)
    internal
    {
        _nftAuctions[tokenId].minPrice = 0;
        _nftAuctions[tokenId].buyNowPrice = 0;
        _nftAuctions[tokenId].endTime = 0;
        _nftAuctions[tokenId].bidPeriod = 0;
        _nftAuctions[tokenId].bidIncRate = 0;
        _nftAuctions[tokenId].seller = address(0);
        _nftAuctions[tokenId].whitelistedBuyer = address(0);
        _nftAuctions[tokenId].erc20Token = address(0);
    }

    function _resetBids(uint256 tokenId)
    internal
    {
        _nftAuctions[tokenId].highestBidder = address(0);
        _nftAuctions[tokenId].highestBid = 0;
        _nftAuctions[tokenId].recipient = address(0);
    }

    function _isWhitelistedSale(uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_nftAuctions[tokenId].whitelistedBuyer != address(0));
    }
}