//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../library/LTypes.sol";
import "../interface/INFTEngine.sol";
import "../interface/ICustomNFTMock.sol";

///@title NFT Marketplace Engine for PlayEstates
///@dev NFTEngineV2 is used to create sales & auctions and manage them effectively for seller,  buyers and bidders.
contract NFTEngineV2 is Initializable, OwnableUpgradeable, INFTEngine {

    mapping(LTypes.NFTTypes => address) private _nftContracts;

    mapping(address => mapping(uint256 => LTypes.AuctionNFT)) private _nftAuctions;

    mapping(address => uint256[]) private _nftIdsForAction;

    mapping(address => mapping(uint256 => LTypes.SellNFT)) private _nftSales;

    mapping(address => uint256[]) private _nftIdsForSale;

    mapping(address => mapping(uint256 => LTypes.MintNFT)) private _nftMints;

    address private _treasury;

    uint256 public constant feeToTreasury = 5;

    uint32 public constant defaultBidIncRate = 100;

    uint32 public constant minSettableIncRate = 100;

    uint32 public constant maxMinPriceRate = 8000;

    uint32 public constant defaultAuctionBidPeriod = 86400;    // 1 day

    modifier onlyValidPrice(uint256 price) {
        require(price > 0, "Price cannot be 0");
        _;
    }

    modifier onlyNotSale(address nftContract, uint256 tokenId) {
        require(_nftSales[nftContract][tokenId].seller == address(0), 
            "Not allowed saling token");
        _;
    }

    modifier onlySale(address nftContract, uint256 tokenId) {
        require(_nftSales[nftContract][tokenId].seller != address(0), 
            "Not sale token");
        _;
    }

    modifier onlyAuctionSeller(address nftContract, uint256 tokenId) {
        require(_nftSales[nftContract][tokenId].seller == msg.sender, 
            "Only owner can do it");
        _;
    }

    modifier onlyNotAuctionSeller(address nftContract, uint256 tokenId) {
        require(_nftSales[nftContract][tokenId].seller != msg.sender, 
            "Owner can't bid on own Auction");
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
            !_isWhitelistedAuction(nftContract, tokenId) ||
                _nftAuctions[nftContract][tokenId].whitelistedBuyer == msg.sender,
            "Only the whitelisted buyer"
        );
        _;
    }

    modifier onlyPaymentAcceptable(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 amount
    ) {
        require(
            _isPaymentAccepted(
                nftContract,
                tokenId,
                erc20Token,
                amount
            ),
            "Bid to be in specified ERC20/Eth"
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

    function setNFTContracts(
        address customNFT, 
        address fractionalNFT,
        address membershipNFT,
        address owndNFT)
    external {
        require(
            customNFT != address(0) && 
            fractionalNFT != address(0) && 
            membershipNFT != address(0) && 
            owndNFT != address(0), "Invalid nft contracts' address" 
        );

        _nftContracts[LTypes.NFTTypes.customNFT] = customNFT;
        _nftContracts[LTypes.NFTTypes.fractionalNFT] = fractionalNFT;
        _nftContracts[LTypes.NFTTypes.membershipNFT] = membershipNFT;
        _nftContracts[LTypes.NFTTypes.owndNFT] = owndNFT;
    }

    function removeNftIdFromSells(address nftContract, uint256 nftId) 
    internal {
        for (uint256 i = 0; i < _nftIdsForSale[nftContract].length; i++) {
            if (_nftIdsForSale[nftContract][i] == nftId) {
                for (uint256 j = i; j < _nftIdsForSale[nftContract].length - 1; j++) {
                    _nftIdsForSale[nftContract][j] = _nftIdsForSale[nftContract][j + 1];
                }
                _nftIdsForSale[nftContract].pop();
            }
        }
        delete _nftSales[nftContract][nftId];
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
    }

    function changeTreasury(address newTreasury)
    external onlyOwner {
        require(newTreasury != address(0), "Invalid new treasury");
        _treasury = newTreasury;
    }

    /**
     @notice Setup parameters applicable to all auctions and whitelised sales:
     @param nftContract NFT collection's contract address
     @param tokenId NFT token id for auction
     @param erc20Token ERC20 Token for payment (if specified by the seller)
     @param minPrice minimum price
     @param buyNowPrice buy now price
     @param feeRecipients The fee recipients addresses
     @param feeRates their respective percentages for a sucessful auction/sale
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external {
        require(msg.sender == IERC721(nftContract).ownerOf(tokenId),
            "Sender isn't owner of NFT");
        
        require(_nftAuctions[nftContract][tokenId].seller == address(0),
            "The token's auction has started");

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
            _getBidIncreasePercentage(nftContract,tokenId)
        );

        _updateOngoingAuction(nftContract, tokenId);
    }

    function settleAuction(address nftContract, uint256 tokenId) 
    external {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not NFT owner"
        );
        require(
            !_isAuctionOngoing(nftContract, tokenId),
            "Auction is finished or not created yet"
        );

        _transferNftAndPaySeller(nftContract, tokenId);
        emit NFTAuctionSettled(nftContract, tokenId, msg.sender);
    }

    function withdrawAuction(address nftContract, uint256 tokenId)
    external {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not NFT owner"
        );
        _resetAuction(nftContract, tokenId);
        emit NFTAuctionWithdrawn(nftContract, tokenId);
    }

    function takeHighestBid(address nftContract, uint256 tokenId)
    external
    onlyAuctionSeller(nftContract, tokenId)
    {
        require(
            _isAlreadyBidMade(nftContract, tokenId),
            "cannot payout 0 bid"
        );
        _transferNftToAuctionContract(nftContract, tokenId, msg.sender);
        _transferNftAndPaySeller(nftContract, tokenId);
        emit NFTAuctionHighestBidTaken(nftContract, tokenId);
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
        _makeBid(nftContract, tokenId, erc20Token, amount);
    }    

    function withdrawBid(address nftContract, uint256 tokenId) 
    external {
        address nftHighestBidder = _nftAuctions[nftContract][
            tokenId
        ].highestBidder;
        require(msg.sender == nftHighestBidder, "Highest bidder only can withdraw funds");

        uint128 nftHighestBid = _nftAuctions[nftContract][
            tokenId
        ].highestBid;

        _resetBids(nftContract, tokenId);
        _payout(nftContract, tokenId, nftHighestBidder, nftHighestBid);

        emit NFTAuctionBidWithdrawn(nftContract, tokenId, msg.sender);
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

        _transferNftToAuctionContract(nftContract, tokenId, msg.sender);

        _nftIdsForSale[nftContract].push(tokenId);

        _nftSales[nftContract][tokenId].erc20Token = erc20Token;
        _nftSales[nftContract][tokenId].seller = msg.sender;
        _nftSales[nftContract][tokenId].price = sellPrice;        
        _nftSales[nftContract][tokenId].feeRecipients = feeRecipients;
        _nftSales[nftContract][tokenId].feeRates = feeRates;

        emit NFTTokenSaleCreated(
            nftContract,
            tokenId, 
            msg.sender,
            erc20Token,
            sellPrice
        );
    }

    function withdrawSale(address nftContract, uint256 tokenId)
    external
    onlyTokenOwner(nftContract, tokenId)
    onlySale(nftContract, tokenId) {
        _resetSale(nftContract, tokenId);
        IERC721(nftContract).safeTransferFrom(
            address(this), 
            msg.sender, 
            tokenId
        );
        emit NFTTokenSaleWithdrawn(
            nftContract, 
            tokenId
        );    
    }

    function getNFTContract(uint256 nftType)
    external
    view returns (address) {
        return _nftContracts[LTypes.NFTTypes(nftType)];
    }

    function getTokensOnSale(address nftContract) 
    external 
    view returns (uint256[] memory) {
        return _nftIdsForSale[nftContract];
    }

    function getTokenSaleInfo(address nftContract, uint256 tokenId) 
    external 
    view returns (LTypes.SellNFT memory) {
        return _nftSales[nftContract][tokenId];
    }

    function getTokensOnAuction(address nftContract) 
    external 
    view returns (uint256[] memory) {
        return _nftIdsForAction[nftContract];
    }

    function getTokenAuctionInfo(address nftContract, uint256 tokenId) 
    external 
    view returns (LTypes.AuctionNFT memory) {
        return _nftAuctions[nftContract][tokenId];
    }

    function buyNFT(address nftContract, uint256 tokenId) 
    external 
    payable
    onlySale(nftContract, tokenId)
    onlyNotTokenOwner(nftContract, tokenId) {
        require(msg.sender != address(0), "Invalid nft buyer");
        uint256 amount = _nftSales[nftContract][tokenId].price;
        uint256 toTreasury = amount * feeToTreasury / 100;
        uint256 toSeller = amount - toTreasury;
        address seller = _nftSales[nftContract][tokenId].seller;
        
        if (_nftSales[nftContract][tokenId].erc20Token == address(0)) {
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

            if (!IERC20(_nftSales[nftContract][tokenId].erc20Token).transferFrom(
                msg.sender, seller, toSeller)) {
                revert("Failed sending erc20 to seller");
            }

            if (!IERC20(_nftSales[nftContract][tokenId].erc20Token).transferFrom(
                msg.sender, _treasury, toTreasury)) {
                revert("Failed sending erc20 to treasury");
            }
        }    

        _resetSale(nftContract, tokenId);

        IERC721(nftContract).safeTransferFrom(
            address(this), 
            msg.sender, 
            tokenId
        );

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
        _nftAuctions[nftContract][tokenId].erc20Token = erc20Token;            
        _nftAuctions[nftContract][tokenId].feeRecipients = feeRecipients;
        _nftAuctions[nftContract][tokenId].feeRates = feeRates;
        _nftAuctions[nftContract][tokenId].buyNowPrice = buyNowPrice;
        _nftAuctions[nftContract][tokenId].minPrice = minPrice;
        _nftAuctions[nftContract][tokenId].seller = msg.sender;

        _nftIdsForAction[nftContract].push(tokenId);
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

    function _makeBid(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 tokenAmount
    )
    internal
    onlyNotAuctionSeller(nftContract, tokenId)
    onlyPaymentAcceptable(
        nftContract,
        tokenId,
        erc20Token,
        tokenAmount
    )
    {
        require(
            _doesBidMeetBidRequirements(nftContract, tokenId, tokenAmount),
            "Not enough funds to bid on NFT"
        );

        _reversePreviousBidAndUpdateHighestBid(
            nftContract,
            tokenId,
            tokenAmount
        );
        emit NFTAuctionBidMade(
            nftContract,
            tokenId,
            msg.sender,
            msg.value,
            erc20Token,
            tokenAmount
        );

        _updateOngoingAuction(nftContract, tokenId);
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

    /**
     * @notice Check that a bid is applicable for the purchase of the NFT.
     * In the case of a sale: the bid needs to meet the buyNowPrice.
     * In the case of an auction: the bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address nftContract,
        uint256 tokenId,
        uint128 tokenAmount
    ) internal view returns (bool) {
        uint128 buyNowPrice = _nftAuctions[nftContract][tokenId].buyNowPrice;
        //if buyNowPrice is met, ignore increase percentage
        if (
            buyNowPrice > 0 &&
            (msg.value >= buyNowPrice || tokenAmount >= buyNowPrice)
        ) {
            return true;
        }

        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (_nftAuctions[nftContract][tokenId].highestBid *
            (10000 + _getBidIncreasePercentage(nftContract, tokenId))) / 10000;

        return (msg.value >= bidIncreaseAmount ||
            tokenAmount >= bidIncreaseAmount);
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

    function _getAuctionBidPeriod(address nftContract, uint256 tokenId)
    internal
    view
    returns (uint32)
    {
        uint32 auctionBidPeriod = _nftAuctions[nftContract][tokenId].bidPeriod;

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
        address nftSeller = _nftAuctions[nftContract][tokenId].seller;

        if (_isBuyNowPriceMet(nftContract, tokenId)) {
            _transferNftToAuctionContract(nftContract, tokenId, nftSeller);
            _transferNftAndPaySeller(nftContract, tokenId);
            return;
        }
        //min price not set, nft not up for auction yet
        if (_isMinimumBidMade(nftContract, tokenId)) {
            _transferNftToAuctionContract(nftContract, tokenId, nftSeller);
            _updateAuctionEnd(nftContract, tokenId);
        }
    }

    function _transferNftToAuctionContract(address nftContract, uint256 tokenId, address nftSeller) 
    internal {
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

    function _isPaymentAccepted(
        address nftContract,
        uint256 tokenId,
        address bidERC20Token,
        uint128 tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = _nftAuctions[nftContract][tokenId].erc20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            return
                msg.value == 0 &&
                auctionERC20Token == bidERC20Token &&
                tokenAmount > 0;
        } else {
            return
                msg.value != 0 &&
                bidERC20Token == address(0) &&
                tokenAmount == 0;
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

    function _resetSale(address nftContract, uint256 tokenId) 
    internal {
        removeNftIdFromSells(nftContract, tokenId);
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

        removeNftIdFromAuctions(nftContract, tokenId);
    }

    function _resetBids(address nftContract, uint256 tokenId)
    internal
    {
        _nftAuctions[nftContract][tokenId].highestBidder = address(0);
        _nftAuctions[nftContract][tokenId].highestBid = 0;
        _nftAuctions[nftContract][tokenId].recipient = address(0);
    }

    function _isWhitelistedAuction(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_nftAuctions[nftContract][tokenId].whitelistedBuyer != address(0));
    }

    function _updateHighestBid(
        address nftContract,
        uint256 tokenId,
        uint128 tokenAmount
    ) internal {
        address auctionERC20Token = _nftAuctions[nftContract][tokenId].erc20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
            _nftAuctions[nftContract][tokenId].highestBid = tokenAmount;
        } else {
            _nftAuctions[nftContract][tokenId].highestBid = uint128(msg.value);
        }
        _nftAuctions[nftContract][tokenId].highestBidder = msg.sender;
    }

    function _reverseAndResetPreviousBid(
        address nftContract,
        uint256 tokenId
    ) internal {
        address nftHighestBidder = _nftAuctions[nftContract][
            tokenId
        ].highestBidder;

        uint128 nftHighestBid = _nftAuctions[nftContract][
            tokenId
        ].highestBid;

        _resetBids(nftContract, tokenId);
        _payout(nftContract, tokenId, nftHighestBidder, nftHighestBid);
    }

    function _reversePreviousBidAndUpdateHighestBid(
        address nftContract,
        uint256 tokenId,
        uint128 tokenAmount
    ) internal {
        address prevNftHighestBidder = _nftAuctions[nftContract][
            tokenId
        ].highestBidder;

        uint256 prevNftHighestBid = _nftAuctions[nftContract][
            tokenId
        ].highestBid;

        _updateHighestBid(nftContract, tokenId, tokenAmount);
        if (prevNftHighestBidder != address(0)) {
            _payout(
                nftContract,
                tokenId,
                prevNftHighestBidder,
                prevNftHighestBid
            );
        }
    }
}