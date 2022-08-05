//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../library/LTypes.sol";
import "../interface/INFTEngine.sol";
import "../interface/ICustomNFTMock.sol";

contract NFTEngine is Initializable, OwnableUpgradeable, INFTEngine {

    address[] private _nftContracts;

    mapping(address => mapping(uint256 => LTypes.AuctionNFT)) private _nftAuctions;

    mapping(address => uint256[]) private _nftIdsForAction;

    mapping(address => mapping(uint256 => LTypes.SellNFT)) private _nftSells;

    mapping(address => uint256[]) private _nftIdsForSell;

    mapping(address => mapping(uint256 => LTypes.MintNFT)) private _nftMints;

    address private _treasury;

    uint256 public constant feeToTreasury = 5;

    uint32 public constant defaultBidIncRate = 100;

    uint32 public constant minSettableIncRate = 86400;

    uint32 public constant maxMinPriceRate = 100;

    uint32 public constant defaultAuctionBidPeriod = 8000;

    modifier onlyValidPrice(uint256 price) {
        require(price > 0, "Price cannot be 0");
        _;
    }

    modifier onlyNotSale(address nftContract, uint256 tokenId) {
        require(_nftSells[nftContract][tokenId].seller == address(0), 
            "Not allowed saling token");
        _;
    }

    modifier onlySale(address nftContract, uint256 tokenId) {
        require(_nftSells[nftContract][tokenId].seller != address(0), 
            "Not sale token");
        _;
    }

    modifier onlyTokenOwner(address nftContract, uint256 tokenId) {
        require(msg.sender == IERC721(nftContract).ownerOf(tokenId),
            "Sender isn't owner of NFT");
        _;
    }

    modifier onlyApprovedToken(address nftContract, uint256 tokenId) {
        require(address(this) == IERC721(nftContract).getApproved(tokenId),
            "NFT is not approved by Marketplace");
        _;
    }

    modifier onlyNotTokenOwner(address nftContract, uint256 tokenId) {
        require(msg.sender != IERC721(nftContract).ownerOf(tokenId),
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

    modifier auctionOngoing(address nftContract, uint256 tokenId) {
        require(
            _isAuctionOngoing(nftContract, tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier onlyApplicableBuyer(address nftContract, uint256 tokenId) {
        require(
            !_isWhitelistedSale(nftContract, tokenId) ||
                _nftAuctions[nftContract][tokenId].whitelistedBuyer == msg.sender,
            "Only the whitelisted buyer"
        );
        _;
    }

    function initialize(address admin, address treasury) 
    initializer public {
        require(admin != address(0), "Invalid marketplace owner");
        require(treasury != address(0), "Invalid treasury address");
        
        __Ownable_init();
        _treasury = treasury;
        transferOwnership(admin);
    }

    function removeNftIdFromSells(address nftContract, uint256 nftId) 
    internal {
        for (uint256 i = 0; i < _nftIdsForSell[nftContract].length; i++) {
            if (_nftIdsForSell[nftContract][i] == nftId) {
                for (uint256 j = i; j < _nftIdsForSell[nftContract].length - 1; j++) {
                    _nftIdsForSell[nftContract][j] = _nftIdsForSell[nftContract][j + 1];
                }
                _nftIdsForSell[nftContract].pop();
            }
        }
        delete _nftSells[nftContract][nftId];
    }

    function removeNftIdFromAuctions(address nftContract, uint256 nftId) 
    internal {
        for (uint256 i = 0; i < _nftIdsForAction[nftContract].length; i++) {
            if (_nftIdsForAction[nftContract][i] == nftId) {
                for (uint256 j = i; j < _nftIdsForAction[nftContract].length - 1; j++) {
                    _nftIdsForAction[nftContract][j] = _nftIdsForAction[nftContract][j + 1];
                }
                _nftIdsForAction[nftContract].pop();
            }
        }
        delete _nftAuctions[nftContract][nftId];
    }

    function changeTreasury(address newTreasury)
    external onlyOwner {
        require(newTreasury != address(0), "Invalid new treasury");
        _treasury = newTreasury;
    }

    function createAuction(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external {
        
        _setupAuction(
            nftContract,
            tokenId,
            erc20Token,
            minPrice,
            buyNowPrice,
            feeRecipients,
            feeRates
        );

        emit NFTAuctionCreated(
            nftContract,
            tokenId,
            msg.sender,
            erc20Token,
            minPrice,
            buyNowPrice,
            _getAuctionBidPeriod(nftContract,tokenId),
            _getBidIncreasePercentage(nftContract,tokenId),
            feeRecipients,
            feeRates
        );

        _updateOngoingAuction(nftContract, tokenId);
    }

    function calcAuction() external {

    }

    function claimAuction() external {

    }

    function makeBid(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 amount
    ) 
    external 
    payable 
    auctionOngoing(nftContract, tokenId) 
    onlyApplicableBuyer(nftContract, tokenId) {
        
    }

    function withdrawBid() external {
        
    }

    function createSale(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 sellPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external 
    onlyTokenOwner(nftContract, tokenId)
    onlyApprovedToken(nftContract, tokenId)
    onlyValidPrice(sellPrice) 
    onlyNotSale(nftContract, tokenId) {

        _nftIdsForSell[nftContract].push(tokenId);

        _nftSells[nftContract][tokenId].erc20Token = erc20Token;
        _nftSells[nftContract][tokenId].seller = msg.sender;
        _nftSells[nftContract][tokenId].price = sellPrice;        
        _nftSells[nftContract][tokenId].feeRecipients = feeRecipients;
        _nftSells[nftContract][tokenId].feeRates = feeRates;

        emit NFTTokenSaleCreated(
            nftContract,
            tokenId, 
            msg.sender,
            erc20Token,
            sellPrice
        );
    }

    function cancelSale(address nftContract, uint256 tokenId)
    external
    onlyTokenOwner(nftContract, tokenId)
    onlySale(nftContract, tokenId) {
        delete _nftSells[nftContract][tokenId];
        removeNftIdFromSells(nftContract, tokenId);

        emit NFTTokenSaleCanceled(
            nftContract, 
            tokenId
        );    
    }

    function getNFTContracts()
    external
    view returns (address[] memory) {
        return _nftContracts;
    }

    function getTokensOnSale(address nftContract) 
    external 
    view returns (uint256[] memory) {
        return _nftIdsForSell[nftContract];
    }

    function getTokenSaleInfo(address nftContract, uint256 tokenId) 
    external 
    view returns (LTypes.SellNFT memory) {
        return _nftSells[nftContract][tokenId];
    }

    function buyNFT(address nftContract, uint256 tokenId) 
    external 
    payable
    onlySale(nftContract, tokenId)
    onlyNotTokenOwner(nftContract, tokenId) {
        require(msg.sender != address(0), "Invalid nft buyer");
        uint256 amount = _nftSells[nftContract][tokenId].price;
        uint256 toTreasury = amount * feeToTreasury / 100;
        uint256 toSeller = amount - toTreasury;
        address seller = _nftSells[nftContract][tokenId].seller;
        
        if (_nftSells[nftContract][tokenId].erc20Token == address(0)) {
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

            if (!IERC20(_nftSells[nftContract][tokenId].erc20Token).transferFrom(
                msg.sender, seller, toSeller)) {
                revert("Failed sending erc20 to seller");
            }

            if (!IERC20(_nftSells[nftContract][tokenId].erc20Token).transferFrom(
                msg.sender, _treasury, toTreasury)) {
                revert("Failed sending erc20 to treasury");
            }
        }    

        delete _nftSells[nftContract][tokenId];
        removeNftIdFromSells(nftContract, tokenId);

        IERC721(nftContract).safeTransferFrom(seller, msg.sender, tokenId);

        emit NFTTokenSaleClosed(
            nftContract, 
            tokenId, 
            msg.sender
        );    
    }

    function mintNFT(address erc20, uint256 price, uint256 royalty, string memory uri) 
    external {        
        // IERC721Mock(_nftContract).safeMint(msg.sender, uri);
    }
    
    function nftOwner(address nftContract, uint256 tokenId) 
    external 
    view returns (address) {
        return IERC721(nftContract).ownerOf(tokenId);       
    }

    function _setupAuction(
        address nftContract,
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
            _nftAuctions[nftContract][tokenId].erc20Token = erc20Token;
        }
        _nftAuctions[nftContract][tokenId].feeRecipients = feeRecipients;
        _nftAuctions[nftContract][tokenId].feeRates = feeRates;
        _nftAuctions[nftContract][tokenId].buyNowPrice = buyNowPrice;
        _nftAuctions[nftContract][tokenId].minPrice = minPrice;
        _nftAuctions[nftContract][tokenId].seller = msg.sender;
    }

    function _isAuctionOngoing(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        // if the Auction's endTime is set to 0, the auction is technically on-going, however
        // the minimum bid price (minPrice) has not yet been met.
        return (_nftAuctions[nftContract][tokenId].endTime == 0 ||
            block.timestamp < _nftAuctions[nftContract][tokenId].endTime);
    }

    function _isAlreadyBidMade(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_nftAuctions[nftContract][tokenId].highestBid > 0);
    }

    function _isMinimumBidMade(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 minPrice = _nftAuctions[nftContract][tokenId].minPrice;
        return ( minPrice > 0 &&
            (_nftAuctions[nftContract][tokenId].highestBid >= minPrice));
    }

    function _isBuyNowPriceMet(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 buyNowPrice = _nftAuctions[nftContract][tokenId].buyNowPrice;
        return (buyNowPrice > 0 &&
            _nftAuctions[nftContract][tokenId].highestBid >= buyNowPrice);
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

    function _getAuctionBidPeriod(address nftContract, uint256 _tokenId)
    internal
    view
    returns (uint32)
    {
        uint32 auctionBidPeriod = _nftAuctions[nftContract][_tokenId].bidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    function _getNftRecipient(address nftContract, uint256 tokenId)
    internal
    view
    returns (address)
    {
        address nftRecipient = _nftAuctions[nftContract][tokenId].recipient;

        if (nftRecipient == address(0)) {
            return _nftAuctions[nftContract][tokenId].highestBidder;
        } else {
            return nftRecipient;
        }
    }

    function _getBidIncreasePercentage(
        address nftContract, 
        uint256 tokenId
    ) 
    internal 
    view returns (uint32) {
        uint32 bidIncreasePercentage = _nftAuctions[nftContract][tokenId].bidIncRate;

        if (bidIncreasePercentage == 0) {
            return defaultBidIncRate;
        } else {
            return bidIncreasePercentage;
        }
    }

    function _updateOngoingAuction(address nftContract, uint256 tokenId) 
    internal {
        if (_isBuyNowPriceMet(nftContract, tokenId)) {
            _transferNftToAuctionContract(nftContract, tokenId);
            _transferNftAndPaySeller(nftContract, tokenId);
            return;
        }
        //min price not set, nft not up for auction yet
        if (_isMinimumBidMade(nftContract, tokenId)) {
            _transferNftToAuctionContract(nftContract, tokenId);
            _updateAuctionEnd(nftContract, tokenId);
        }
    }

    function _transferNftToAuctionContract(address nftContract, uint256 tokenId) 
    internal {
        address nftSeller = _nftAuctions[nftContract][tokenId].seller;

        if (IERC721(nftContract).ownerOf(tokenId) == nftSeller) {
            IERC721(nftContract).transferFrom(
                nftSeller,
                address(this),
                tokenId
            );
            require(
                IERC721(nftContract).ownerOf(tokenId) == address(this),
                "nft transfer failed"
            );
        } else {
            require(
                IERC721(nftContract).ownerOf(tokenId) == address(this),
                "Seller doesn't own NFT"
            );
        }
    }

    function _transferNftAndPaySeller(
        address nftContract, 
        uint256 tokenId
    ) internal {
        address nftSeller = _nftAuctions[nftContract][tokenId].seller;
        address nftHighestBidder = _nftAuctions[nftContract][tokenId].highestBidder;
        address nftRecipient = _getNftRecipient(nftContract, tokenId);
        uint128 nftHighestBid = _nftAuctions[nftContract][tokenId].highestBid;
        _resetBids(nftContract, tokenId);

        _payFeesAndSeller(
            nftContract,
            tokenId,
            nftSeller,
            nftHighestBid
        );
        IERC721(nftContract).transferFrom(
            address(this),
            nftRecipient,
            tokenId
        );

        _resetAuction(nftContract, tokenId);
        emit NFTAuctionPaid(
            nftContract,
            tokenId,
            nftSeller,
            nftHighestBid,
            nftHighestBidder,
            nftRecipient
        );
    }

    function _payFeesAndSeller(
        address nftContract,
        uint256 tokenId,
        address nftSeller,
        uint256 highestBid
    ) internal {
        uint256 feesPaid;
        for (uint256 i = 0; i < _nftAuctions[nftContract][tokenId] .feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(
                highestBid,
                _nftAuctions[nftContract][tokenId].feeRates[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                nftContract,
                tokenId,
                _nftAuctions[nftContract][tokenId].feeRecipients[i],
                fee
            );
        }
        _payout(
            nftContract,
            tokenId,
            nftSeller,
            (highestBid - feesPaid)
        );
    }

    function _payout(
        address nftContract,
        uint256 tokenId,
        address recipient,
        uint256 amount
    ) internal {
        address auctionERC20Token = _nftAuctions[nftContract][tokenId].erc20Token;
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

    function _updateAuctionEnd(address nftContract, uint256 tokenId) internal {
        //the auction end is always set to now + the bid period
        _nftAuctions[nftContract][tokenId].endTime =
            _getAuctionBidPeriod(nftContract, tokenId) + uint64(block.timestamp);

        emit NFTAuctionUpdated(
            nftContract,
            tokenId,
            _nftAuctions[nftContract][tokenId].endTime
        );
    }

    function _resetAuction(address nftContract, uint256 tokenId)
    internal
    {
        _nftAuctions[nftContract][tokenId].minPrice = 0;
        _nftAuctions[nftContract][tokenId].buyNowPrice = 0;
        _nftAuctions[nftContract][tokenId].endTime = 0;
        _nftAuctions[nftContract][tokenId].bidPeriod = 0;
        _nftAuctions[nftContract][tokenId].bidIncRate = 0;
        _nftAuctions[nftContract][tokenId].seller = address(0);
        _nftAuctions[nftContract][tokenId].whitelistedBuyer = address(0);
        _nftAuctions[nftContract][tokenId].erc20Token = address(0);
    }

    function _resetBids(address nftContract, uint256 tokenId)
    internal
    {
        _nftAuctions[nftContract][tokenId].highestBidder = address(0);
        _nftAuctions[nftContract][tokenId].highestBid = 0;
        _nftAuctions[nftContract][tokenId].recipient = address(0);
    }

    function _isWhitelistedSale(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_nftAuctions[nftContract][tokenId].whitelistedBuyer != address(0));
    }
}