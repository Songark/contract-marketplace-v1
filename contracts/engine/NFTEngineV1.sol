//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
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

    /// @notice Emitted when the auction's highestbid is zero
    error NFTEngineDidNotBid(address nftContract, uint256 tokenId);

    /// @notice Emitted when not highest bidder will try to withdraw funds
    error NFTEngineNotHighestBidder(address nftContract, uint256 tokenId);

    /// @notice Emitted when erc20 token transfer failed in payout
    error NFTEngineERC20TransferFailed(address erc20token, uint256 amount);

    AggregatorV3Interface internal priceFeedUsd; 

    /// @dev Mapping of each NFT types and nft contracts
    mapping(LTypes.NFTTypes => address) private _tokenContracts;

    mapping(LTypes.PayTypes => address) private _tokenPayments;

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

    /// @dev Backend wallet address for buying NFT with Fiat USD 
    address private _admin;

    /// @dev Fee percentage for treasury
    uint256 public constant feeToTreasury = 5;

    /// @dev Default bid increase rate ( 0 ~ 10000 )
    uint32 public constant defaultBidIncRate = 100;

    /// @dev Minimum settable increase rate ( 0 ~ 10000 )
    uint32 public constant minSettableIncRate = 100;

    /// @dev Maximum limitation of min price ( 0 ~ 10000 )
    uint32 public constant maxMinPriceRate = 8000;

    /// @dev Maximum fee recipients length
    uint32 public constant maxFeeRecipients = 5;  

    /// @dev Default bid period for auction ( seconds )
    uint256 public constant defaultAuctionBidPeriod = 7 * 86400;    // 1 week
   
    /// @dev Throws if called with invalid payment type
    modifier onlyValidPayTypes(uint256 payType) {
        require(payType >= 0 && payType <= uint256(LTypes.PayTypes.payFiat), 
            "Invalid pay type");
        _;
    }
    
    /// @dev Throws if called with not saling nft token id
    modifier onlySale(address nftContract, uint256 tokenId) {
        if (_mapSaleIds[nftContract][tokenId] == 0)
            revert NFTEngineNotSalingToken(nftContract, tokenId);
        _;
    }

    /// @dev Throws if called with not auctioning nft token id
    modifier onlyAuction(address nftContract, uint256 tokenId) {
        if (_mapAuctionIds[nftContract][tokenId] == 0)
            revert NFTEngineNotAuctionToken(nftContract, tokenId);
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

    /// @dev Throws if nft token is not approved by marketplace
    modifier onlyApprovedToken(address nftContract, uint256 tokenId) {
        if (address(this) != IERC721(nftContract).getApproved(tokenId))
            revert NFTEngineNotApprovedToken(nftContract, tokenId);
        _;
    }

    /// @dev Throws if called with not on-going auction
    modifier auctionOngoing(address nftContract, uint256 tokenId) {
        if (!_isAuctionOngoing(nftContract, tokenId))
            revert NFTEngineAuctionFinished(nftContract, tokenId);
        _;
    }

    /// @dev See {NFTEngineFactory-createNFTEngine} for more infos about params, initializer for upgradable
    /// @param newOwner address of administrator who can manage the created marketplace engine
    /// @param treasury address of treasury for getting fee
    function initialize(address newOwner, address treasury) 
    initializer external {
        __Ownable_init();
        __ReentrancyGuard_init();
        _treasury = treasury;
        transferOwnership(newOwner);
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

    function setAdmin(address admin) 
    external 
    onlyOwner {
        _admin = admin;
    }

    function setAggregatorV3(address feed)
    external onlyOwner {
        priceFeedUsd = AggregatorV3Interface(feed);
    }

    /// @notice Set nft contracts address to the marketplace engine
    /// @dev marketplace engine will use these 4 types of nft contracts for sales and auctions
    /// @param nftType type of nft contracts, between 0 and 3
    /// @param nftContract address of nft contract contract
    function setNFTContract(uint256 nftType, address nftContract)
    external onlyOwner {
        require(nftContract != address(0),
            "Invalid nft contract address");
        require(nftType >= 0 && nftType <= uint256(LTypes.NFTTypes.customNFT), 
            "Invalid nft type");

        _tokenContracts[LTypes.NFTTypes(nftType)] = nftContract;
        emit NFTContractUpdated(nftType, nftContract);
    }

    /// @notice Set erc20 token contract address to the marketplace engine
    /// @dev marketplace engine will use this erc20 token for payment option
    /// @param paymentToken address of erc20 token contract
    function setPaymentContract(uint256 payType, address paymentToken)
    external 
    onlyOwner onlyValidPayTypes(payType) {
        require(paymentToken != address(0),
            "Invalid pay token address");

        _tokenPayments[LTypes.PayTypes(payType)] = paymentToken;
        emit PaymentContractUpdated(payType, paymentToken);
    }

    /// @notice Get nft contract address from type
    /// @dev everyone can get one of 2 types nft contracts using this function
    /// @param tokenType see the enum values {LTypes::NFTTypes}
    /// @return nftContract nft contract address
    function getContractAddress(uint256 tokenType)
    external
    view returns (address) {
        return _tokenContracts[LTypes.NFTTypes(tokenType)];
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
    /// @param payType payment type
    /// @param minPrice minimum price
    /// @param buyNowPrice buy now price
    /// @param bidPeriod bid period seconds
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 payType,
        uint256 minPrice,
        uint256 buyNowPrice,
        uint256 bidPeriod
    ) external 
    onlyValidPayTypes(payType) 
    nonReentrant {
        require(payType != uint256(LTypes.PayTypes.payFiat), "Not support USD in auction");

        _checkNftContract(nftContract, tokenId);
        _checkPrice(minPrice);
        _checkPrice(buyNowPrice);

        if (_mapAuctionIds[nftContract][tokenId] > 0)
            revert NFTEngineSellerCant(nftContract, tokenId);

        _setupAuction(
            nftContract,
            tokenId,
            payType,
            minPrice,
            buyNowPrice,
            bidPeriod
        );

        emit NFTAuctionCreated(
            nftContract,
            tokenId,
            msg.sender,
            payType,
            minPrice,
            buyNowPrice,
            _getAuctionBidPeriod(nftContract, tokenId)
        );
    }

    /// @notice Settle progressing auction for nft token
    /// @dev any user can settle the expired auctions using this function, 
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for settle auction
    function settleAuction(address nftContract, uint256 tokenId) 
    external 
    nonReentrant
    onlyAuction(nftContract, tokenId)
    auctionOngoing(nftContract, tokenId) {
        _transferNftAndPaySeller(nftContract, tokenId);

        emit NFTAuctionSettled(nftContract, tokenId, msg.sender);
    }

    /// @notice Withdraw progressing auction for nft token
    /// @dev NFT auction creators can withdraw their auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for withdraw auction
    function withdrawAuction(address nftContract, uint256 tokenId)
    external 
    nonReentrant {
        _checkNftContract(nftContract, tokenId);
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
    /// @param payType Payment type
    /// @param payPrice ERC20 token amount for payment
    function makeBid(
        address nftContract,
        uint256 tokenId,
        uint256 payType,
        uint256 payPrice
    ) 
    external 
    payable 
    nonReentrant
    onlyNotAuctionSeller(nftContract, tokenId)
    auctionOngoing(nftContract, tokenId) {
        _makeBid(nftContract, tokenId, payType, payPrice);
    }    

    /// @notice Make a bid request for on going auction with payment parameters
    /// @dev internal function for makeBid() external
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for making bid
    /// @param payType Payment type
    /// @param payPrice Ether or ERC20 token amount for payment
    function _makeBid(
        address nftContract,
        uint256 tokenId,
        uint256 payType,
        uint256 payPrice
    )
    internal {
        uint256 _payType = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].payType;
        require(payType == _payType, 
            "Not allowed paytype by seller");

        require(_doesBidMeetBidRequirements(nftContract, tokenId, payPrice),
            "Insufficient funds to bid"
        );

        _reversePreviousBidAndUpdateHighestBid(
            nftContract,
            tokenId,
            payPrice
        );
        
        _updateOngoingAuction(nftContract, tokenId);

        emit NFTAuctionBidMade(
            nftContract,
            tokenId,
            msg.sender,
            payType,
            payPrice
        );
    }

    /// @notice Withdraw own bid from on going auction
    /// @dev NFT bidders can withdraw their bid on the specific auction using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for making bid
    function withdrawBid(address nftContract, uint256 tokenId) 
    external 
    nonReentrant 
    onlyAuction(nftContract, tokenId)
    {
        address nftHighestBidder = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBidder;
        
        if (msg.sender != nftHighestBidder)
            revert NFTEngineNotHighestBidder(nftContract, tokenId);

        uint256 nftHighestBid = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBid;

        uint256 payType = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].payType;

        _resetBids(nftContract, tokenId);
        _payout(
            nftHighestBidder, 
            nftHighestBid,
            payType);

        emit NFTAuctionBidWithdrawn(nftContract, tokenId, msg.sender);
    }

    /// @notice Create an sale request with parameters
    /// @dev NFT owners can create sales using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param payType payment type
    /// @param sellPrice sell price with USD currency
    function createSale(
        address nftContract,
        uint256 tokenId,
        uint256 payType,
        uint256 sellPrice
    ) external nonReentrant    
    onlyApprovedToken(nftContract, tokenId)
    onlyValidPayTypes(payType) {        
        _checkNftContract(nftContract, tokenId);
        _checkPrice(sellPrice);
        _createSale(nftContract, tokenId, payType, sellPrice);
    }

    /// @notice Create an sale request with parameters
    /// @dev internal function for createSale() external
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param sellPrice sell price  with USD unit
    function _createSale(
        address nftContract,
        uint256 tokenId,
        uint256 payType,
        uint256 sellPrice
    ) internal {
        _transferNftToAuctionContract(nftContract, tokenId, msg.sender);

        _mapSaleIds[nftContract][tokenId] = _arrSales[nftContract].length + 1;
        LTypes.SellNFT storage _saleInfo = _arrSales[nftContract].push();

        _saleInfo.tokenId = tokenId;
        _saleInfo.seller = msg.sender;
        _saleInfo.payType = payType;        
        _saleInfo.price = sellPrice;        

        emit NFTTokenSaleCreated(
            nftContract,
            tokenId, 
            msg.sender,
            payType,
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
    onlyAuction(nftContract, tokenId)
    view returns (LTypes.AuctionNFT memory) {
        return _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1];
    }

    function getAuctionNextBiddablePrice(address nftContract, uint256 tokenId) 
    external 
    onlyAuction(nftContract, tokenId)
    view returns (uint256) {
        uint256 bidIncreaseAmount = (
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid *
            (10000 + defaultBidIncRate)) / 10000;
        return bidIncreaseAmount;
    }

    /// @notice Buy one nft token from backend with fiat USD payment
    /// @dev NFT buyers can purchase nft token from USD payment through backend
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for buying
    /// @param paidPrice paid amount from buyer
    /// @param buyer buyer address
    function buyNFTwithFiat(address nftContract, uint256 tokenId, uint256 paidPrice, address buyer) 
    external 
    nonReentrant
    onlySale(nftContract, tokenId) {
        require(msg.sender == _admin, "Allowed only backend owner");
        require(buyer != address(0), "Invalid buyer address");
        
        address _seller = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].seller;
        uint256 _toSeller = paidPrice - paidPrice * feeToTreasury / 100;
        _resetSale(nftContract, tokenId);

        IERC721(nftContract).safeTransferFrom(
            address(this), 
            buyer, 
            tokenId
        );
        
        emit NFTTokenSaleClosed(
            nftContract, 
            tokenId, 
            buyer
        );   

        emit NFTPayFiatToSeller(
            _seller,
            _toSeller
        );
    }

    /// @notice Buy one nft token from progressing sale
    /// @dev NFT buyers can purchase nft token from sales using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for buying
    function buyNFT(address nftContract, uint256 tokenId, uint256 payType) 
    external 
    payable
    nonReentrant
    onlySale(nftContract, tokenId) {
        address _seller = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].seller;
        if (_seller == msg.sender) {
            revert NFTEngineSellerCant(nftContract, tokenId);
        }            
        uint256 _payType = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].payType;
        uint256 _payPrice = _arrSales[nftContract][_mapSaleIds[nftContract][tokenId] - 1].price;
        uint256 _toTreasury = _payPrice * feeToTreasury / 100;
        uint256 _toSeller = _payPrice - _toTreasury;
        _resetSale(nftContract, tokenId);

        require(payType == _payType || _payType == uint256(LTypes.PayTypes.payAll),
            "Not allowed payment type by seller");

        bool isSent = false;
        if (payType == uint256(LTypes.PayTypes.payFiat)) {
            // pay with fiat USD, checking for verification
            revert("Allowed only for backend");
        }
        else if (payType == uint256(LTypes.PayTypes.payEther)) {
            /// paying with ether or matic
            require(msg.value >= _payPrice, "Insufficient ether to buy");

            (isSent, ) = payable(_seller).call{
                value: _toSeller
            }("");
            require(isSent, 'failed to send eth to seller');

            (isSent, ) = payable(_treasury).call{
                value: _toTreasury
            }("");              
            require(isSent, 'failed to send eth to treasury');                               
        }
        else if (payType == uint256(LTypes.PayTypes.payUSDC)) {
            /// paying with erc20 token : USDC
            address erc20Token = _tokenPayments[LTypes.PayTypes(payType)];
            require (
                IERC20(erc20Token).transferFrom(msg.sender, _seller, _toSeller) &&
                IERC20(erc20Token).transferFrom(msg.sender, _treasury, _toTreasury),
                "failed to send USDC to seller");
        }    
        else {
            /// paying with erc20 token : PBRT
            address erc20Token = _tokenPayments[LTypes.PayTypes(payType)];
            require (
                IERC20(erc20Token).transferFrom(msg.sender, _seller, _toSeller) &&
                IERC20(erc20Token).transferFrom(msg.sender, _treasury, _toTreasury),
                "failed to send PBRT to seller");
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
    /// @param payType payment type
    /// @param minPrice minimum price
    /// @param buyNowPrice buy now price
    /// @param bidPeriod bid period seconds
    function _setupAuction(
        address nftContract,
        uint256 tokenId,
        uint256 payType,
        uint256 minPrice,
        uint256 buyNowPrice,
        uint256 bidPeriod
    ) internal {   
        if (_getPortionOfBid(buyNowPrice, maxMinPriceRate) < minPrice)
            revert NFTEngineInvalidMinPrice(minPrice, buyNowPrice);        

        _mapAuctionIds[nftContract][tokenId] = _arrAuctions[nftContract].length + 1;
        LTypes.AuctionNFT storage _auctionInfo = _arrAuctions[nftContract].push();

        _auctionInfo.seller = msg.sender;
        _auctionInfo.tokenId = tokenId;                 
        _auctionInfo.payType = payType;   
        _auctionInfo.minPrice = minPrice;
        _auctionInfo.buyNowPrice = buyNowPrice;
        _auctionInfo.bidPeriod = bidPeriod;
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
        uint256 minPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].minPrice;
        return (_arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid >= minPrice);
    }

    /// @notice If the buy now price is set by the seller, check that the highest bid meets that price.
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id
    function _isBuyNowPriceMet(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint256 buyNowPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].buyNowPrice;
        return (_arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid >= buyNowPrice);
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
        uint256 tokenAmount
    ) internal view returns (bool) {
        // if buyNowPrice is met, ignore increase percentage
        uint256 minPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].minPrice;
        uint256 buyNowPrice = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].buyNowPrice;
        uint256 payType = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].payType;

        // if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid *
            (10000 + defaultBidIncRate)) / 10000;

        if (payType == uint256(LTypes.PayTypes.payEther)) {
            if (msg.value >= buyNowPrice || 
                (msg.value >= minPrice && bidIncreaseAmount == 0) ||
                (msg.value >= bidIncreaseAmount && bidIncreaseAmount > 0))
                return true;        
        }
        else {
            if (tokenAmount >= buyNowPrice || 
                (tokenAmount >= minPrice && bidIncreaseAmount == 0) ||
                (tokenAmount >= bidIncreaseAmount && bidIncreaseAmount > 0))
                return true;        
        }
        return false;
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
    returns (uint256)
    {
        uint256 auctionBidPeriod = _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].bidPeriod;
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
        uint256 nftHighestBid = _arrAuctions[nftContract][index].highestBid;
        uint256 payType = _arrAuctions[nftContract][index].payType;
        address nftRecipient = _getNftRecipient(nftContract, tokenId);        

        _resetBids(nftContract, tokenId);
        _resetAuction(nftContract, tokenId);

        _payFeesAndSeller(
            nftSeller,
            nftHighestBid,
            payType
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
        uint256 payType
    ) internal {
        uint256 toTreasury = highestBid * feeToTreasury / 100;
        highestBid = highestBid - toTreasury;

        _payout(
            _treasury,
            toTreasury,
            payType
        );

        _payout(
            nftSeller,
            highestBid,
            payType
        );
    }

    /// @notice Pays the specific amount of ethereum or erc20 tokens to the recipient wallet
    function _payout(
        address recipient,
        uint256 payPrice,
        uint256 payType
    ) internal {   
        LTypes.PayTypes _payType = LTypes.PayTypes(payType);
        if (_payType == LTypes.PayTypes.payEther) {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(recipient).call{
                value: payPrice,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            require (success, "Failed to send eth to recipient");
        }
        else if (_payType == LTypes.PayTypes.payUSDC) {
            require(IERC20(_tokenPayments[_payType]).transfer(recipient, payPrice), 
                "fail send USDC to recipient");              
        }
        else if (_payType == LTypes.PayTypes.payPBRT) {
            require(IERC20(_tokenPayments[_payType]).transfer(recipient, payPrice), 
                "fail send PBRT to recipient");              
        } else {
            emit NFTPayFiatToSeller(recipient, payPrice);
        }
    }

    /// @notice Increase the specific auction's end timestamp with the bid period seconds
    function _updateAuctionEnd(address nftContract, uint256 tokenId) internal {
        //the auction end is always set to now + the bid period
        _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].endTime =
            _getAuctionBidPeriod(nftContract, tokenId) + uint128(block.timestamp);

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
        uint256 tokenAmount
    ) internal {
        LTypes.PayTypes payType = LTypes.PayTypes(
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].payType);

        if (payType == LTypes.PayTypes.payEther) {
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid = msg.value;
        }
        else if (payType == LTypes.PayTypes.payUSDC || payType == LTypes.PayTypes.payPBRT) {
            address auctionERC20Token = _tokenPayments[payType];
            require(auctionERC20Token != address(0) &&
                IERC20(auctionERC20Token).transferFrom(msg.sender, address(this), tokenAmount),
                "fail to receive pay from buyer");
            _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBid = tokenAmount;
        }
        else {

        }
        _arrAuctions[nftContract][_mapAuctionIds[nftContract][tokenId] - 1].highestBidder = msg.sender;
    }

    /// @notice Reverse transfers the ethereum or erc20 token to the previous highest bidder 
    /// and updating the new highest bidder with tokenAmount
    function _reversePreviousBidAndUpdateHighestBid(
        address nftContract,
        uint256 tokenId,
        uint256 tokenAmount
    ) internal {
        address prevNftHighestBidder = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBidder;

        uint256 prevNftHighestBid = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].highestBid;

        uint256 payType = _arrAuctions[nftContract][
            _mapAuctionIds[nftContract][tokenId] - 1
        ].payType;

        _updateHighestBid(nftContract, tokenId, tokenAmount);
        if (prevNftHighestBidder != address(0)) {
            _payout(
                prevNftHighestBidder,
                prevNftHighestBid,
                payType
            );
        }
    }

    function _checkNftContract(address nftContract, uint256 tokenId)
    internal view {
        require (nftContract != address(0),
            "Invalid nft contract");

        require (
            nftContract == _tokenContracts[LTypes.NFTTypes.membershipNFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.peasNFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.pnftSSNFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.pnftSNFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.pnftANFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.pnftBNFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.pnftCNFT] || 
            nftContract == _tokenContracts[LTypes.NFTTypes.customNFT], 
            "Unregistered nft contract");

        if (msg.sender != IERC721(nftContract).ownerOf(tokenId))
            revert NFTEngineNotTokenOwner(nftContract, tokenId);
    }

    function _checkPrice(uint256 price) 
    internal pure {
        if (price == 0) {
            revert NFTEngineInvalidPrice(price);
        }
    }

    /// @dev get Eth / Matic price from USD price, usdPrice: USD Price * 100000000, ETH Price (wei)
    function getEthFromUsd(uint256 usdPrice) 
    public 
    view returns (uint256) 
    {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeedUsd.latestRoundData();
        return usdPrice * (10 ** 26) / uint256(price);                
    }    
}
