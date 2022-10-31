//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../library/LTypes.sol";
import "../interface/INFTEngine.sol";

/// @title NFT Marketplace Engine for PlayEstates
/// @dev NFTEngineV1 is used to create sales & auctions and manage them effectively for seller,  buyers and bidders.
contract NFTEngineV1 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC721Receiver, INFTEngine {
    /// @notice Emitted when invalid basket address will be inputed
    error NFTEngineInvalidPrice(uint256 price);

    /// @notice Emitted when saling token will be inputed for creating new sale
    error NFTEngineAlreadySalingToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when not saling token will be inputed
    error NFTEngineNotSalingToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when not auction token will be inputed
    error NFTEngineNotAuctionToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when not auction seller will be inputed for managing auction
    error NFTEngineNotAuctionSeller(address seller);

    /// @notice Emitted when not sale seller will be inputed for managing sale
    error NFTEngineNotSaleSeller(address seller);

    /// @notice Emitted when seller will try to make bid or buy nft
    error NFTEngineSellerCant(address nftContract, uint256 tokenId);

    /// @notice Emitted when invalid token owner will try to approve the token
    error NFTEngineNotTokenOwner(address nftContract, uint256 tokenId);

    /// @notice Emitted when token owner will try to bid the auction
    error NFTEngineTokenOwner(address nftContract, uint256 tokenId);

    /// @notice Emitted when nft token will not be approved for engine
    error NFTEngineNotApprovedToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when the minPrice is greater than 80% of buyNowPrice"
    error NFTEngineInvalidMinPrice(uint256 minPrice, uint256 buyNowPrice);

    /// @notice Emitted when the length of recipients and fee rates are not same"
    error NFTEngineIncorrentLength(uint256 recipients, uint256 rates);

    /// @notice Emitted when the sum of fee rates exceeds the maximum
    error NFTEngineFeeRatesExceed();

    /// @notice Emitted when the auction has been finished
    error NFTEngineAuctionFinished(address nftContract, uint256 tokenId);

    /// @notice Emitted when the buyer will try to use invalid token for payment
    error NFTEngineNotAcceptablePayment(address nftContract, uint256 tokenId);

    /// @notice Emitted when the auction's highestbid is zero
    error NFTEngineDidNotBid(address nftContract, uint256 tokenId);

    /// @notice Emitted when not highest bidder will try to withdraw funds
    error NFTEngineNotHighestBidder(address nftContract, uint256 tokenId);

    /// @notice Emitted when erc20 token transfer failed in payout
    error NFTEngineERC20TransferFailed(address erc20token, uint256 amount);

    /// @dev Mapping of each NFT types and nft contracts
    mapping(LTypes.TokenTypes => address) private _tokenContracts;

    /// @dev Nested mapping of nft contract address vs tokenId vs array index
    mapping(address => mapping(uint256 => uint256)) private _mapAuctionIds;

    /// @dev Array mapping of nft contract and auction info for auction
    mapping(address => LTypes.AuctionNFT[]) private _arrAuctions;

    /// @dev Nested mapping of nft contract address vs tokenId vs array index
    mapping(address => mapping(uint256 => uint256)) private _mapSaleIds;

    /// @dev Array mapping of nft contract and sell info for sale
    mapping(address => LTypes.SellNFT[]) private _arrSales;

    /// @dev Treasury address for getting fee
    address private _treasury;

    /// @dev Fee percentage for treasury
    uint256 public constant feeToTreasury = 5;

    /// @dev Default bid increase rate ( 0 ~ 10000 )
    uint32 public constant defaultBidIncRate = 100;

    /// @dev Minimum settable increase rate ( 0 ~ 10000 )
    uint32 public constant minSettableIncRate = 100;

    /// @dev Maximum limitation of min price ( 0 ~ 10000 )
    uint32 public constant maxMinPriceRate = 8000;

    /// @dev Default bid period for auction ( seconds )
    uint32 public constant defaultAuctionBidPeriod = 86400;    // 1 day

    /// @dev Maximum fee recipients length
    uint32 public constant maxFeeRecipients = 5;  

    /// @dev Throws if called with invalid price
    modifier onlyValidPrice(uint256 price) {
        if (price == 0) {
            revert NFTEngineInvalidPrice(price);
        }
        _;
    }

    /// @dev Throws if called with not saling nft token id
    modifier onlySale(address nftContract, uint256 tokenId) {
        if (_mapSaleIds[nftContract][tokenId] == 0)
            revert NFTEngineNotSalingToken(nftContract, tokenId);
        _;
    }

    /// @dev Throws if called by invalid seller of the auction
    modifier onlyAuctionSeller(address nftContract, uint256 tokenId) {
        if (_mapAuctionIds[nftContract][tokenId] == 0 ||
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].seller != msg.sender) 
            revert NFTEngineNotAuctionSeller(msg.sender);
        _;
    }

    /// @dev Throws if called by invalid seller of the sale
    modifier onlySaleSeller(address nftContract, uint256 tokenId) {
        if (_mapSaleIds[nftContract][tokenId] == 0 || 
            _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].seller != msg.sender) 
            revert NFTEngineNotSaleSeller(msg.sender);
        _;
    }

    /// @dev Throws if called by seller of the auction
    modifier onlyNotAuctionSeller(address nftContract, uint256 tokenId) {
        if (_mapAuctionIds[nftContract][tokenId] == 0 ||
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].seller == msg.sender)
            revert NFTEngineSellerCant(nftContract, tokenId);
        _;
    }

    /// @dev Throws if called by seller of the sale
    modifier onlyNotSaleSeller(address nftContract, uint256 tokenId) {
        if (_mapSaleIds[nftContract][tokenId] == 0 ||
            _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].seller == msg.sender)
            revert NFTEngineSellerCant(nftContract, tokenId);
        _;
    }

    /// @dev Throws if called by invalid nft token owner
    modifier onlyTokenOwner(address nftContract, uint256 tokenId) {
        require (nftContract == _tokenContracts[LTypes.TokenTypes.membershipNFT] || 
            nftContract == _tokenContracts[LTypes.TokenTypes.customNFT], 
            "Unregistered nft contract");

        if (msg.sender != IERC721(nftContract).ownerOf(tokenId))
            revert NFTEngineNotTokenOwner(nftContract, tokenId);
        _;
    }

    /// @dev Throws if nft token is not approved by marketplace
    modifier onlyApprovedToken(address nftContract, uint256 tokenId) {
        if (address(this) != IERC721(nftContract).getApproved(tokenId))
            revert NFTEngineNotApprovedToken(nftContract, tokenId);
        _;
    }

    /// @dev Throws if called with different length of recipients and rates
    modifier checkSizeRecipientsAndRates(
        uint256 recipients, uint256 rates
    ) {
        if (recipients != rates || recipients > maxFeeRecipients)
            revert NFTEngineIncorrentLength(recipients, rates);
        _;
    }

    /// @dev Throws if called with invalid fee rates, sum of fee rates is smaller than 10000
    modifier checkFeeRatesLessThanMaximum(
        uint32[] memory feeRates
    ) {
        uint32 totalPercent;
        for (uint8 i = 0; i < feeRates.length; i++) {
            totalPercent += feeRates[i];
            if (totalPercent > 10000) {
                revert NFTEngineFeeRatesExceed();
            }
        }        
        _;
    }

    /// @dev Throws if called with not on-going auction
    modifier auctionOngoing(address nftContract, uint256 tokenId) {
        if (!_isAuctionOngoing(nftContract, tokenId))
            revert NFTEngineAuctionFinished(nftContract, tokenId);
        _;
    }

    /// @dev See {NFTEngineFactory-createNFTEngine} for more infos about params, initializer for upgradable
    /// @param admin address of administrator who can manage the created marketplace engine
    /// @param treasury address of treasury for getting fee
    function initialize(address admin, address treasury) 
    initializer external {
        __Ownable_init();
        __ReentrancyGuard_init();
        _treasury = treasury;
        transferOwnership(admin);
    }

    /// @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
    /// by `operator` from `from`, this function is called.
    /// It must return its Solidity selector to confirm the token transfer.
    /// If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
    /// The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Set nft contracts address to the marketplace engine
    /// @dev marketplace engine will use these 4 types of nft contracts for sales and auctions
    /// @param nftType type of nft contracts, between 0 and 3
    /// @param nftContract address of nft contract contract
    function setNFTContract(uint256 nftType, address nftContract)
    external onlyOwner {
        require(nftContract != address(0),
            "Invalid nft contract address");
        require(nftType >= 0 && nftType <= uint256(LTypes.TokenTypes.customNFT), 
            "Invalid nft type");

        _tokenContracts[LTypes.TokenTypes(nftType)] = nftContract;

        emit NFTContractUpdated(nftType, nftContract);
    }

    /// @notice Set erc20 token contract address to the marketplace engine
    /// @dev marketplace engine will use this erc20 token for payment option
    /// @param paymentToken address of erc20 token contract
    function setPaymentContract(address paymentToken)
    external onlyOwner {
        require(paymentToken != address(0),
            "Invalid payment token address");

        _tokenContracts[LTypes.TokenTypes.erc20Token] = paymentToken;

        emit NFTContractUpdated(uint256(LTypes.TokenTypes.erc20Token), paymentToken);
    }

    /// @notice Get nft or erc20 contract address from type
    /// @dev everyone can get one of 4 types nft contracts using this function
    /// @param tokenType see the enum values {LTypes::TokenTypes}
    /// @return nftContract nft contract address
    function getContractAddress(uint256 tokenType)
    external
    view returns (address) {
        return _tokenContracts[LTypes.TokenTypes(tokenType)];
    }

    /// @notice Remove token id from sales list
    /// @dev marketplace engine will call this function after finishing sale
    /// @param nftContract NFT collection's contract address
    /// @param nftId NFT token id 
    function removeNftIdFromSells(address nftContract, uint256 nftId) 
    internal {
        uint256 index = _mapSaleIds[nftContract][nftId];
        uint256 length = _arrSales[nftContract].length;
        delete _mapSaleIds[nftContract][nftId];
        if (index < length) {
            uint256 lastnftId = _arrSales[nftContract][length - 1].tokenId;
            _mapSaleIds[nftContract][lastnftId] = index;
            _arrSales[nftContract][index - 1] = _arrSales[nftContract][length - 1];
        }
        _arrSales[nftContract].pop();
    }

    /// @notice Remove token id from auctions list
    /// @dev marketplace engine will call this function after finishing auction
    /// @param nftContract NFT collection's contract address
    /// @param nftId NFT token id 
    function removeNftIdFromAuctions(address nftContract, uint256 nftId) 
    internal {
        uint256 index = _mapAuctionIds[nftContract][nftId];
        uint256 length = _arrAuctions[nftContract].length;
        delete _mapAuctionIds[nftContract][nftId];
        if (index < length) {
            uint256 lastnftId = _arrAuctions[nftContract][length - 1].tokenId;
            _mapAuctionIds[nftContract][lastnftId] = index;
            _arrAuctions[nftContract][index - 1] = _arrAuctions[nftContract][length - 1];
        }
        _arrAuctions[nftContract].pop();
    }

    /// @notice Create an auction request with parameters
    /// @dev NFT owners can create auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param minPrice minimum price
    /// @param buyNowPrice buy now price
    /// @param bidPeriod bid period seconds
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients
    function createAuction(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        uint256 bidPeriod,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external nonReentrant {
        require (nftContract == _tokenContracts[LTypes.TokenTypes.membershipNFT] || 
            nftContract == _tokenContracts[LTypes.TokenTypes.customNFT], 
            "Unregistered nft contract");

        require(erc20Token == _tokenContracts[LTypes.TokenTypes.erc20Token] || 
            erc20Token == address(0), "Unregistered payment contract");

        if (msg.sender != IERC721(nftContract).ownerOf(tokenId))
            revert NFTEngineNotTokenOwner(nftContract, tokenId);
        
        if (_mapAuctionIds[nftContract][tokenId] > 0)
            revert NFTEngineSellerCant(nftContract, tokenId);

        _setupAuction(
            nftContract,
            tokenId,
            erc20Token,
            minPrice,
            buyNowPrice,
            bidPeriod,
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
            _getAuctionBidPeriod(nftContract,tokenId)
        );

        _updateOngoingAuction(nftContract, tokenId);
    }

    /// @notice Settle progressing auction for nft token
    /// @dev any user can settle the expired auctions using this function, 
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for settle auction
    function settleAuction(address nftContract, uint256 tokenId) 
    external nonReentrant
    auctionOngoing(nftContract, tokenId) {

        _transferNftAndPaySeller(nftContract, tokenId);
        emit NFTAuctionSettled(nftContract, tokenId, msg.sender);
    }

    /// @notice Withdraw progressing auction for nft token
    /// @dev NFT auction creators can withdraw their auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for withdraw auction
    function withdrawAuction(address nftContract, uint256 tokenId)
    external nonReentrant
    onlyTokenOwner(nftContract, tokenId) {
        _resetAuction(nftContract, tokenId);
        emit NFTAuctionWithdrawn(nftContract, tokenId);
    }

    /// @notice Complete progressing auction with current highest bid
    /// @dev NFT auction creators can complete their auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for complete auction
    function takeHighestBid(address nftContract, uint256 tokenId)
    external nonReentrant
    onlyAuctionSeller(nftContract, tokenId)
    {
        if (!_isAlreadyBidMade(nftContract, tokenId))
            revert NFTEngineDidNotBid(nftContract, tokenId);

        _transferNftToAuctionContract(nftContract, tokenId, msg.sender);
        _transferNftAndPaySeller(nftContract, tokenId);
        emit NFTAuctionHighestBidTaken(nftContract, tokenId);
    }

    /// @notice Make a bid request for on going auction with payment parameters
    /// @dev NFT bidders can make a bid on the specific auction using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for making bid
    /// @param erc20Token ERC20 token for payment (if specified by the seller)
    /// @param amount ERC20 token amount for payment
    function makeBid(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 amount
    ) 
    external 
    nonReentrant
    payable 
    onlyNotAuctionSeller(nftContract, tokenId)
    auctionOngoing(nftContract, tokenId) {
        _makeBid(nftContract, tokenId, erc20Token, amount);
    }    

    /// @notice Make a bid request for on going auction with payment parameters
    /// @dev internal function for makeBid() external
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for making bid
    /// @param erc20Token ERC20 token for payment (if specified by the seller)
    /// @param tokenAmount ERC20 token amount for payment
    function _makeBid(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 tokenAmount
    )
    internal {
        if (!_isPaymentAccepted(nftContract,tokenId,erc20Token, tokenAmount))
            revert NFTEngineNotAcceptablePayment(nftContract, tokenId);

        require(
            _doesBidMeetBidRequirements(nftContract, tokenId, tokenAmount),
            "Insufficient funds to bid"
        );

        _reversePreviousBidAndUpdateHighestBid(
            nftContract,
            tokenId,
            tokenAmount
        );
        
        _updateOngoingAuction(nftContract, tokenId);

        emit NFTAuctionBidMade(
            nftContract,
            tokenId,
            msg.sender,
            msg.value,
            erc20Token,
            tokenAmount
        );
    }

    /// @notice Withdraw own bid from on going auction
    /// @dev NFT bidders can withdraw their bid on the specific auction using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for making bid
    function withdrawBid(address nftContract, uint256 tokenId) 
    external nonReentrant {
        address nftHighestBidder = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBidder;
        
        if (msg.sender != nftHighestBidder)
            revert NFTEngineNotHighestBidder(nftContract, tokenId);

        uint128 nftHighestBid = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBid;

        address erc20Token = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].erc20Token;

        _resetBids(nftContract, tokenId);
        _payout(
            nftHighestBidder, 
            nftHighestBid,
            erc20Token);

        emit NFTAuctionBidWithdrawn(nftContract, tokenId, msg.sender);
    }

    /// @notice Create an sale request with parameters
    /// @dev NFT owners can create sales using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param sellPrice sell price
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients
    function createSale(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 sellPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external nonReentrant
    onlyTokenOwner(nftContract, tokenId)
    onlyApprovedToken(nftContract, tokenId)
    onlyValidPrice(sellPrice) {        
        require(erc20Token == _tokenContracts[LTypes.TokenTypes.erc20Token] || 
            erc20Token == address(0), "Unregistered payment contract");

        _createSale(nftContract, tokenId, erc20Token, sellPrice, feeRecipients, feeRates);
        
    }

    /// @notice Create an sale request with parameters
    /// @dev internal function for createSale() external
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param sellPrice sell price
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients
    function _createSale(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 sellPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) internal
        checkSizeRecipientsAndRates(
        feeRecipients.length, feeRates.length
    )
    checkFeeRatesLessThanMaximum(feeRates) {
        _transferNftToAuctionContract(nftContract, tokenId, msg.sender);

        _mapSaleIds[nftContract][tokenId] = _arrSales[nftContract].length + 1;
        LTypes.SellNFT storage _saleInfo = _arrSales[nftContract].push();

        _saleInfo.tokenId = tokenId;
        _saleInfo.erc20Token = erc20Token;
        _saleInfo.seller = msg.sender;
        _saleInfo.price = sellPrice;        
        _saleInfo.feeRecipients = feeRecipients;
        _saleInfo.feeRates = feeRates;

        emit NFTTokenSaleCreated(
            nftContract,
            tokenId, 
            msg.sender,
            erc20Token,
            sellPrice
        );
    }

    /// @notice Withdraw a progressing sale for nft token
    /// @dev NFT sellers can withdraw their sale using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for withdraw sale
    function withdrawSale(address nftContract, uint256 tokenId)
    external nonReentrant
    onlySaleSeller(nftContract, tokenId) {
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

    /// @notice Get saling nft tokens array from contract address
    /// @dev NFT buyers can get list of sale nfts using this function
    /// @param nftContract nft contract address
    /// @return tokenInfos nftToken Info's array of nft tokenIds
    function getTokenInfosOnSale(address nftContract) 
    external 
    view returns (LTypes.SellNFT[] memory tokenInfos) {
        return _arrSales[nftContract];
    }

    /// @notice Get details information about nft token sale from contract and tokenId
    /// @dev NFT buyers can get information about the nft token sale using this function
    /// @param nftContract NFT contract address
    /// @param tokenId NFT token id for getting information
    /// @return nftSaleInfo filled with SellNFT structure object
    function getTokenSaleInfo(address nftContract, uint256 tokenId) 
    external 
    onlySale(nftContract, tokenId)
    view returns (LTypes.SellNFT memory) {
        return _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1];
    }

    /// @notice Get auction nft tokens array from contract address
    /// @dev NFT bidders can get list of auction nfts using this function
    /// @param nftContract nft contract address
    /// @return tokenInfos nftToken Info's array of nft tokenIds
    function getTokenInfosOnAuction(address nftContract) 
    external 
    view returns (LTypes.AuctionNFT[] memory tokenInfos) {        
        return _arrAuctions[nftContract];
    }

    /// @notice Get details information about nft token auction from contract and tokenId
    /// @dev NFT bidders can get information about the nft token auction using this function
    /// @param nftContract NFT contract address
    /// @param tokenId NFT token id for getting information
    /// @return nftAuctionInfo filled with AuctionNFT structure object
    function getTokenAuctionInfo(address nftContract, uint256 tokenId) 
    external 
    view returns (LTypes.AuctionNFT memory) {
        if (_mapAuctionIds[nftContract][tokenId] == 0)
            revert NFTEngineNotAuctionToken(nftContract, tokenId);

        return _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1];
    }

    /// @notice Buy one nft token from progressing sale
    /// @dev NFT buyers can purchase nft token from sales using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for buying
    function buyNFT(address nftContract, uint256 tokenId) 
    external 
    payable
    nonReentrant
    onlySale(nftContract, tokenId)
    onlyNotSaleSeller(nftContract, tokenId) {
        uint256 amount = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].price;
        address seller = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].seller;
        address erc20Token = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].erc20Token;
        uint256 toTreasury = amount * feeToTreasury / 100;
        uint256 toSeller = amount - toTreasury;
        _resetSale(nftContract, tokenId);
        bool isSent = false;

        if (erc20Token == address(0)) {
            /// paying with ether
            require(msg.value >= amount, "Insufficient ether to buy");

            (isSent, ) = payable(seller).call{
                value: toSeller
            }("");
            require(isSent, 'failed to send eth to seller');

            (isSent, ) = payable(_treasury).call{
                value: toTreasury
            }("");              
            require(isSent, 'failed to send eth to treasury');                               
        }
        else {
            /// paying with erc20 token
            require (
                IERC20(erc20Token).transferFrom(msg.sender, seller, toSeller) &&
                IERC20(erc20Token).transferFrom(msg.sender, _treasury, toTreasury),
                "failed to send pbrt to seller");
        }            

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

    /// @notice Setup parameters applicable to all auctions and whitelised sales:
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param minPrice minimum price
    /// @param buyNowPrice buy now price
    /// @param bidPeriod bid period seconds
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients    
    function _setupAuction(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        uint256 bidPeriod,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    )
    internal    
    checkSizeRecipientsAndRates(
        feeRecipients.length, feeRates.length
    )
    checkFeeRatesLessThanMaximum(feeRates)
    {   
        if (buyNowPrice != 0 &&
            _getPortionOfBid(buyNowPrice, maxMinPriceRate) < minPrice)
            revert NFTEngineInvalidMinPrice(minPrice, buyNowPrice);        

        _mapAuctionIds[nftContract][tokenId] = _arrAuctions[nftContract].length + 1;
        LTypes.AuctionNFT storage _auctionInfo = _arrAuctions[nftContract].push();

        _auctionInfo.tokenId = tokenId;                 
        _auctionInfo.erc20Token = erc20Token;            
        _auctionInfo.feeRecipients = feeRecipients;
        _auctionInfo.feeRates = feeRates;
        _auctionInfo.buyNowPrice = buyNowPrice;
        _auctionInfo.minPrice = minPrice;
        _auctionInfo.seller = msg.sender;
        _auctionInfo.bidPeriod = uint32(bidPeriod);
    }

    /// @notice Checking the auction's status. 
    /// @dev If the Auction's endTime is set to 0, the auction is technically on-going, 
    /// however the minimum bid price (minPrice) has not yet been met.   
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    function _isAuctionOngoing(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {            
        return (_arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].endTime == 0 ||
            block.timestamp < _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].endTime);
    }

    /// @notice Check if a bid has been made. This is applicable in the early bid scenario
    /// to ensure that if an auction is created after an early bid, the auction
    /// begins appropriately or is settled if the buy now price is met.
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id
    function _isAlreadyBidMade(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid > 0);
    }

    /// @notice If the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id
    function _isMinimumBidMade(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 minPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].minPrice;
        return ( minPrice > 0 &&
            (_arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid >= minPrice));
    }

    /// @notice If the buy now price is set by the seller, check that the highest bid meets that price.
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id
    function _isBuyNowPriceMet(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 buyNowPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].buyNowPrice;
        return (buyNowPrice > 0 &&
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid >= buyNowPrice);
    }

    /// @notice Check that a bid is applicable for the purchase of the NFT.
    /// In the case of a sale: the bid needs to meet the buyNowPrice.
    /// In the case of an auction: the bid needs to be a % higher than the previous bid.
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id    
    /// @param tokenAmount erc20 token's amount
    function _doesBidMeetBidRequirements(
        address nftContract,
        uint256 tokenId,
        uint128 tokenAmount
    ) internal view returns (bool) {
        uint128 buyNowPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].buyNowPrice;
        //if buyNowPrice is met, ignore increase percentage
        if (
            buyNowPrice > 0 &&
            (msg.value >= buyNowPrice || tokenAmount >= buyNowPrice)
        ) {
            return true;
        }

        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (_arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid *
            (10000 + defaultBidIncRate)) / 10000;

        return (msg.value >= bidIncreaseAmount ||
            tokenAmount >= bidIncreaseAmount);
    }

    /// @notice Returns the percentage of the total bid (used to calculate fee payments)
    function _getPortionOfBid(uint256 totalBid, uint256 rate)
    internal
    pure returns (uint256)
    {
        return (totalBid * rate) / 10000;
    }

    /// @notice Returns the bid period of an auction from nft contract and token id
    function _getAuctionBidPeriod(address nftContract, uint256 tokenId)
    internal
    view
    returns (uint32)
    {
        uint32 auctionBidPeriod = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].bidPeriod;

        if (auctionBidPeriod == 0) {
            return defaultAuctionBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    /// @notice Returns the default value for the NFT recipient is the highest bidder.
    function _getNftRecipient(address nftContract, uint256 tokenId)
    internal
    view
    returns (address)
    {
        return _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBidder;
    }

    /// @notice Settle an auction or sale if the buyNowPrice is met or set
    /// auction period to begin if the minimum price has been met.
    function _updateOngoingAuction(address nftContract, uint256 tokenId) 
    internal {
        address nftSeller = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].seller;

        if (_isBuyNowPriceMet(nftContract, tokenId)) {
            _transferNftToAuctionContract(nftContract, tokenId, nftSeller);
            _transferNftAndPaySeller(nftContract, tokenId);
            return;
        }
        //min price not set, nft not up for auction yet
        if (_isMinimumBidMade(nftContract, tokenId)) {
            _updateAuctionEnd(nftContract, tokenId);
            _transferNftToAuctionContract(nftContract, tokenId, nftSeller);
        }
    }

    /// @notice Transfers nft token to this marketplace contract
    function _transferNftToAuctionContract(address nftContract, uint256 tokenId, address nftSeller) 
    internal {
        if (IERC721(nftContract).ownerOf(tokenId) == nftSeller) {
            IERC721(nftContract).safeTransferFrom(
                nftSeller,
                address(this),
                tokenId
            );
        } 
    }

    /// @notice Pays the ethereum or erc20 to seller and transferring nft token to highest buyer,
    /// clearing the auction request
    function _transferNftAndPaySeller(
        address nftContract, 
        uint256 tokenId
    ) internal {
        uint256 index = _mapAuctionIds[nftContract][tokenId] - 1;
        address nftSeller = _arrAuctions[nftContract][index].seller;
        address nftHighestBidder = _arrAuctions[nftContract][index].highestBidder;
        uint128 nftHighestBid = _arrAuctions[nftContract][index].highestBid;
        address nftRecipient = _getNftRecipient(nftContract, tokenId);        
        address erc20Token = _arrAuctions[nftContract][index].erc20Token;
        address[] memory feeRecipients = _arrAuctions[nftContract][index].feeRecipients;
        uint32[] memory feeRates = _arrAuctions[nftContract][index].feeRates;

        _resetBids(nftContract, tokenId);
        _resetAuction(nftContract, tokenId);

        _payFeesAndSeller(
            nftSeller,
            nftHighestBid,
            erc20Token,
            feeRecipients,
            feeRates
        );        
        IERC721(nftContract).safeTransferFrom(
            address(this),
            nftRecipient,
            tokenId
        );
        
        emit NFTAuctionPaid(
            nftContract,
            tokenId,
            nftSeller,
            nftHighestBid,
            nftHighestBidder,
            nftRecipient
        );
    }

    /// @notice Pays the fee to treasury and fee recipients, and then send the rest to seller
    function _payFeesAndSeller(
        address nftSeller,
        uint256 highestBid,
        address erc20Token,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) internal {
        uint256 toTreasury = highestBid * feeToTreasury / 100;
        highestBid = highestBid - toTreasury;

        _payout(
            _treasury,
            toTreasury,
            erc20Token
        );

        uint256 feesPaid;
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(
                highestBid,
                feeRates[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                feeRecipients[i],
                fee,
                erc20Token
            );
        }
        _payout(
            nftSeller,
            (highestBid - feesPaid),
            erc20Token
        );
    }

    /// @notice Pays the specific amount of ethereum or erc20 tokens to the recipient wallet
    function _payout(
        address recipient,
        uint256 amount,
        address erc20Token
    ) internal {                
        if (_isERC20Auction(erc20Token)) {
            IERC20(erc20Token).transfer(recipient, amount);                
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(recipient).call{
                value: amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            require (success, "Failed to send eth to recipient");
        }
    }

    /// @notice Payment is accepted in the following scenarios:
    /// (1) Auction already created - can accept ETH or Specified Token
    ///  --------> Cannot bid with ETH & an ERC20 Token together in any circumstance<------
    /// (2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
    /// (3) Cannot make a zero bid (no ETH or Token amount)
    function _isPaymentAccepted(
        address nftContract,
        uint256 tokenId,
        address bidERC20Token,
        uint128 tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].erc20Token;
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

    /// @notice Checks the erc20 token's address and return true if it's not zero.
    function _isERC20Auction(address _auctionERC20Token)
    internal
    pure
    returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    /// @notice Increase the specific auction's end timestamp with the bid period seconds
    function _updateAuctionEnd(address nftContract, uint256 tokenId) internal {
        //the auction end is always set to now + the bid period
        _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].endTime =
            _getAuctionBidPeriod(nftContract, tokenId) + uint64(block.timestamp);

        emit NFTAuctionUpdated(
            nftContract,
            tokenId,
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].endTime
        );
    }

    /// @notice Reset all sale related parameters for an NFT.
    /// this effectively removes an EFT as an item up for sale
    function _resetSale(address nftContract, uint256 tokenId) 
    internal {
        removeNftIdFromSells(nftContract, tokenId);
    }

    /// @notice Reset all auction related parameters for an NFT.
    /// This effectively removes an EFT as an item up for auction
    function _resetAuction(address nftContract, uint256 tokenId)
    internal
    {
        removeNftIdFromAuctions(nftContract, tokenId);
    }

    /// @notice Reset all auction bids related parameters for an NFT.    
    function _resetBids(address nftContract, uint256 tokenId)
    internal
    {
        _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBidder = address(0);
        _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid = 0;
    }

    /// @notice Updates the highest bidder and bid price for an Auction request
    function _updateHighestBid(
        address nftContract,
        uint256 tokenId,
        uint128 tokenAmount
    ) internal {
        address auctionERC20Token = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].erc20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            if (!IERC20(auctionERC20Token).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            )) {
                revert NFTEngineERC20TransferFailed(auctionERC20Token, tokenAmount);
            }
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid = tokenAmount;
        } else {
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid = uint128(msg.value);
        }
        _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBidder = msg.sender;
    }

    /// @notice Reverse transfers the ethereum or erc20 token to the previous highest bidder 
    /// and updating the new highest bidder with tokenAmount
    function _reversePreviousBidAndUpdateHighestBid(
        address nftContract,
        uint256 tokenId,
        uint128 tokenAmount
    ) internal {
        address prevNftHighestBidder = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBidder;

        uint256 prevNftHighestBid = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBid;

        address erc20Token = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].erc20Token;

        _updateHighestBid(nftContract, tokenId, tokenAmount);
        if (prevNftHighestBidder != address(0)) {
            _payout(
                prevNftHighestBidder,
                prevNftHighestBid,
                erc20Token
            );
        }
    }
}
