//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../library/LTypes.sol";
import "../interface/INFTEngine.sol";
// import "hardhat/console.sol";

///@title NFT Marketplace Engine for PlayEstates
///@dev NFTEngineV1 is used to create sales & auctions and manage them effectively for seller,  buyers and bidders.
contract NFTEngineV1 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC721Receiver, INFTEngine {
    /// @notice Emitted when invalid basket address will be inputed
    error NFTEngineInvalidPrice(uint256 price);

    /// @notice Emitted when saling token will be inputed for creating new sale
    error NFTEngineAlreadySalingToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when not saling token will be inputed for buying nft
    error NFTEngineNotSalingToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when not auction seller will be inputed for managing auction
    error NFTEngineNotAuctionSeller(address seller);

    /// @notice Emitted when auction seller will try to make bid on own auction
    error NFTEngineAuctionSellerCant(address nftContract, uint256 tokenId);

    /// @notice Emitted when invalid token owner will try to approve the token
    error NFTEngineNotTokenOwner(address nftContract, uint256 tokenId);

    /// @notice Emitted when token owner will try to bid the auction
    error NFTEngineTokenOwner(address nftContract, uint256 tokenId);

    /// @notice Emitted when nft token will not be approved for engine
    error NFTEngineNotApprovedToken(address nftContract, uint256 tokenId);

    /// @notice Emitted when the minPrice is greater than 80% of buyNowPrice"
    error NFTEngineInvalidMinPrice(uint256 minPrice, uint256 buyNowPrice);

    /// @notice Emitted when the length of recipients and fee rates are not same"
    error NFTEngineNotMatchedLength(uint256 recipients, uint256 rates);

    /// @notice Emitted when the sum of fee rates exceeds the maximum
    error NFTEngineFeeRatesExceed();

    /// @notice Emitted when the auction has been finished
    error NFTEngineAuctionFinished(address nftContract, uint256 tokenId);

    /// @notice Emitted when the not whitelisted buyer will try to buy nft
    error NFTEngineNotWhitelistedBuyer(address nftContract, uint256 tokenId);

    /// @notice Emitted when the buyer will try to use invalid token for payment
    error NFTEngineNotAcceptablePayment(address nftContract, uint256 tokenId);

    /// @notice Emitted when the auction's highestbid is zero
    error NFTEngineDidNotBid(address nftContract, uint256 tokenId);

    /// @notice Emitted when not highest bidder will try to withdraw funds
    error NFTEngineNotHighestBidder(address nftContract, uint256 tokenId);

    /// @notice Emitted when nft transfer failed
    error NFTEngineTokenTransferFailed(address nftContract, uint256 tokenId);

    /// @notice Emitted when erc20 token transfer failed in payout
    error NFTEngineERC20TransferFailed(address erc20token, uint256 amount);

    /// @dev mapping of each NFT types and nft contracts
    mapping(LTypes.NFTTypes => address) private _nftContracts;

    /// @dev nested mapping of nft contract address vs tokenId vs auction item
    mapping(address => mapping(uint256 => LTypes.AuctionNFT)) private _nftAuctions;

    /// @dev array mapping of nft contract and tokenIds for auction
    mapping(address => uint256[]) private _nftIdsForAuction;

    /// @dev nested mapping of nft contract address vs tokenId vs sale item
    mapping(address => mapping(uint256 => LTypes.SellNFT)) private _nftSales;

    /// @dev array mapping of nft contract and tokenIds for sale
    mapping(address => uint256[]) private _nftIdsForSale;

    /// @dev nested mapping of nft contract address vs tokenId vs mint item
    mapping(address => mapping(uint256 => LTypes.MintNFT)) private _nftMints;

    /// @dev treasury address for getting fee
    address private _treasury;

    /// @dev fee percentage for treasury
    uint256 public constant feeToTreasury = 5;

    /// @dev default bid increase rate ( 0 ~ 10000 )
    uint32 public constant defaultBidIncRate = 100;

    /// @dev minimum settable increase rate ( 0 ~ 10000 )
    uint32 public constant minSettableIncRate = 100;

    /// @dev maximum limitation of min price ( 0 ~ 10000 )
    uint32 public constant maxMinPriceRate = 8000;

    /// @dev default bid period for auction ( seconds )
    uint32 public constant defaultAuctionBidPeriod = 86400;    // 1 day

    /// @dev throws if called with invalid price
    modifier onlyValidPrice(uint256 price) {
        if (price == 0) {
            revert NFTEngineInvalidPrice(price);
        }
        _;
    }

    /// @dev throws if called with saling nft token id
    modifier onlyNotSale(address nftContract, uint256 tokenId) {
        if (_nftSales[nftContract][tokenId].seller != address(0)) 
            revert NFTEngineAlreadySalingToken(nftContract, tokenId);
        _;
    }

    /// @dev throws if called with not saling nft token id
    modifier onlySale(address nftContract, uint256 tokenId) {
        if (_nftSales[nftContract][tokenId].seller == address(0))
            revert NFTEngineNotSalingToken(nftContract, tokenId);
        _;
    }

    /// @dev throws if called by invalid seller of the auction
    modifier onlyAuctionSeller(address nftContract, uint256 tokenId) {
        if (_nftSales[nftContract][tokenId].seller != msg.sender) 
            revert NFTEngineNotAuctionSeller(msg.sender);
        _;
    }

    /// @dev throws if called by seller of the auction
    modifier onlyNotAuctionSeller(address nftContract, uint256 tokenId) {
        if (_nftSales[nftContract][tokenId].seller == msg.sender)
            revert NFTEngineAuctionSellerCant(nftContract, tokenId);
        _;
    }

    /// @dev throws if called by invalid nft token owner
    modifier onlyTokenOwner(address nftContract, uint256 tokenId) {
        if (msg.sender != IERC721(nftContract).ownerOf(tokenId))
            revert NFTEngineNotTokenOwner(nftContract, tokenId);
        _;
    }

    /// @dev throws if called by nft token owner
    modifier onlyNotTokenOwner(address nftContract, uint256 tokenId) {
        if (msg.sender == IERC721(nftContract).ownerOf(tokenId))
            revert NFTEngineTokenOwner(nftContract, tokenId);
        _;
    }

    /// @dev throws if nft token is not approved by marketplace
    modifier onlyApprovedToken(address nftContract, uint256 tokenId) {
        if (address(this) != IERC721(nftContract).getApproved(tokenId))
            revert NFTEngineNotApprovedToken(nftContract, tokenId);
        _;
    }

    /// @dev throws if called with the minimum price smaller than some of the buyNowPrice(if set).
    modifier minPriceNotExceedLimit(
        uint128 buyNowPrice, uint128 minPrice 
    ) {
        if (buyNowPrice != 0 &&
            _getPortionOfBid(buyNowPrice, maxMinPriceRate) < minPrice)
            revert NFTEngineInvalidMinPrice(minPrice, buyNowPrice);                                
        _;
    }

    /// @dev throws if called with different length of recipients and rates
    modifier checkSizeRecipientsAndRates(
        uint256 recipients, uint256 rates
    ) {
        if (recipients != rates)
            revert NFTEngineNotMatchedLength(recipients, rates);
        _;
    }

    /// @dev throws if called with invalid fee rates, sum of fee rates is smaller than 10000
    modifier checkFeeRatesLessThanMaximum(
        uint32[] memory feeRates
    ) {
        uint32 totalPercent;
        for (uint256 i = 0; i < feeRates.length; i++) {
            totalPercent = totalPercent + feeRates[i];
        }
        if (totalPercent > 10000)
            revert NFTEngineFeeRatesExceed();
        _;
    }

    /// @dev throws if called with not on-going auction
    modifier auctionOngoing(address nftContract, uint256 tokenId) {
        if (!_isAuctionOngoing(nftContract, tokenId))
            revert NFTEngineAuctionFinished(nftContract, tokenId);
        _;
    }

    /// @dev throws if called with not whitelist wallet (if set).
    modifier onlyApplicableBuyer(address nftContract, uint256 tokenId) {
        if (_isWhitelistedAuction(nftContract, tokenId) &&
            _nftAuctions[nftContract][tokenId].whitelistedBuyer != msg.sender)
            revert NFTEngineNotWhitelistedBuyer(nftContract, tokenId);
        _;
    }

    /// @dev throws if called with incorrect payment token and amount for making bid.
    modifier onlyPaymentAcceptable(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 amount
    ) {
        if (!_isPaymentAccepted(
                nftContract,
                tokenId,
                erc20Token,
                amount
            ))
            revert NFTEngineNotAcceptablePayment(nftContract, tokenId);
        _;
    }

    /// @dev see {NFTEngineFactory-createNFTEngine} for more infos about params, initializer for upgradable
    /// @param admin address of administrator who can manage the created marketplace engine
    /// @param treasury address of treasury for getting fee
    function initialize(address admin, address treasury) 
    initializer public {
        require(admin != address(0));
        require(treasury != address(0));
        
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

    /// @notice set nft contracts address to marketplace engine
    /// @dev marketplace engine will use these 4 types of nft contracts for sales and auctions
    /// @param customNFT address of custom nft contract for game items
    /// @param fractionalNFT address of fractional nft contract for pnft
    /// @param membershipNFT address of membership contract
    /// @param owndNFT address of ownedtoken contract
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
            owndNFT != address(0)
        );

        _nftContracts[LTypes.NFTTypes.customNFT] = customNFT;
        _nftContracts[LTypes.NFTTypes.fractionalNFT] = fractionalNFT;
        _nftContracts[LTypes.NFTTypes.membershipNFT] = membershipNFT;
        _nftContracts[LTypes.NFTTypes.owndNFT] = owndNFT;
    }

    /// @notice remove token id from sales list
    /// @dev marketplace engine will call this function after finishing sale
    /// @param nftContract NFT collection's contract address
    /// @param nftId NFT token id 
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

    /// @notice remove token id from auctions list
    /// @dev marketplace engine will call this function after finishing auction
    /// @param nftContract NFT collection's contract address
    /// @param nftId NFT token id 
    function removeNftIdFromAuctions(address nftContract, uint256 nftId) 
    internal {
        for (uint256 i = 0; i < _nftIdsForAuction[nftContract].length; i++) {
            if (_nftIdsForAuction[nftContract][i] == nftId) {
                for (uint256 j = i; j < _nftIdsForAuction[nftContract].length - 1; j++) {
                    _nftIdsForAuction[nftContract][j] = _nftIdsForAuction[nftContract][j + 1];
                }
                _nftIdsForAuction[nftContract].pop();
            }
        }
    }

    /// @notice change treasury address by owner
    /// @dev marketplace engine owner can use this function to change treasury
    /// @param newTreasury address of new treasury
    function changeTreasury(address newTreasury)
    external onlyOwner {
        require(newTreasury != address(0));
        _treasury = newTreasury;
    }

    /// @notice create an auction request with parameters
    /// @dev NFT owners can create auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param minPrice minimum price
    /// @param buyNowPrice buy now price
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients
    function createAuction(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external nonReentrant {
        if (msg.sender != IERC721(nftContract).ownerOf(tokenId))
            revert NFTEngineNotTokenOwner(nftContract, tokenId);
        
        if (_nftAuctions[nftContract][tokenId].seller != address(0))
            revert NFTEngineAuctionSellerCant(nftContract, tokenId);

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

    /// @notice settle progressing auction for nft token
    /// @dev NFT auction creators can settle their auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for settle auction
    function settleAuction(address nftContract, uint256 tokenId) 
    external nonReentrant
    onlyTokenOwner(nftContract, tokenId) 
    auctionOngoing(nftContract, tokenId) {

        _transferNftAndPaySeller(nftContract, tokenId);
        emit NFTAuctionSettled(nftContract, tokenId, msg.sender);
    }

    /// @notice withdraw progressing auction for nft token
    /// @dev NFT auction creators can withdraw their auctions using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for withdraw auction
    function withdrawAuction(address nftContract, uint256 tokenId)
    external nonReentrant
    onlyTokenOwner(nftContract, tokenId) {
        _resetAuction(nftContract, tokenId);
        emit NFTAuctionWithdrawn(nftContract, tokenId);
    }

    /// @notice complete progressing auction with current highest bid
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

    /// @notice make a bid request for on going auction with payment parameters
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
    auctionOngoing(nftContract, tokenId) 
    onlyApplicableBuyer(nftContract, tokenId) {
        _makeBid(nftContract, tokenId, erc20Token, amount);
    }    

    /// @notice withdraw own bid from on going auction
    /// @dev NFT bidders can withdraw their bid on the specific auction using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for making bid
    function withdrawBid(address nftContract, uint256 tokenId) 
    external nonReentrant {
        address nftHighestBidder = _nftAuctions[nftContract][
            tokenId
        ].highestBidder;
        
        if (msg.sender != nftHighestBidder)
            revert NFTEngineNotHighestBidder(nftContract, tokenId);

        uint128 nftHighestBid = _nftAuctions[nftContract][
            tokenId
        ].highestBid;

        _resetBids(nftContract, tokenId);
        _payout(nftContract, tokenId, nftHighestBidder, nftHighestBid);

        emit NFTAuctionBidWithdrawn(nftContract, tokenId, msg.sender);
    }

    /// @notice create an sale request with parameters
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
    onlyValidPrice(sellPrice) 
    onlyNotSale(nftContract, tokenId) {
        
        _createSale(nftContract, tokenId, erc20Token, sellPrice, feeRecipients, feeRates);
        
    }

    /// @notice create a number of sales request with parameters
    /// @dev NFT owners can create sales using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenIds array of NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param sellPrice sell price
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients
    function createBatchSale(
        address nftContract,
        uint256[] memory tokenIds,
        address erc20Token,
        uint128 sellPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) external nonReentrant
    onlyValidPrice(sellPrice) {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (msg.sender != IERC721(nftContract).ownerOf(tokenId))
                revert NFTEngineNotTokenOwner(nftContract, tokenId);
            if (address(this) != IERC721(nftContract).getApproved(tokenId))
                revert NFTEngineNotApprovedToken(nftContract, tokenId);
            if (address(0) != _nftSales[nftContract][tokenId].seller) 
                revert NFTEngineAlreadySalingToken(nftContract, tokenId);

            _createSale(nftContract, tokenId, erc20Token, sellPrice, feeRecipients, feeRates);
        }      
    }

    function _createSale(
        address nftContract,
        uint256 tokenId,
        address erc20Token,
        uint128 sellPrice,
        address[] memory feeRecipients,
        uint32[] memory feeRates
    ) internal {
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

    /// @notice withdraw a progressing sale for nft token
    /// @dev NFT sellers can withdraw their sale using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for withdraw sale
    function withdrawSale(address nftContract, uint256 tokenId)
    external nonReentrant
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

    /// @notice get nft contract address from type
    /// @dev everyone can get one of 4 types nft contracts using this function
    /// @param nftType see the enum values {LTypes::NFTTypes}
    /// @return nftContract nft contract address
    function getNFTContract(uint256 nftType)
    external
    view returns (address) {
        return _nftContracts[LTypes.NFTTypes(nftType)];
    }

    /// @notice get saling nft tokens array from contract address
    /// @dev NFT buyers can get list of sale nfts using this function
    /// @param nftContract nft contract address
    /// @param pageBegin begin index of pagenation
    /// @param pageSize size of pagenation
    /// @return tokenInfos nftToken Info's array of nft tokenIds
    function getTokenInfosOnSale(address nftContract, uint256 pageBegin, uint256 pageSize) 
    external 
    view returns (LTypes.SellNFT[] memory tokenInfos) {
        if (pageBegin < _nftIdsForSale[nftContract].length) {
            if (pageSize > _nftIdsForSale[nftContract].length - pageBegin) {
                pageSize = (_nftIdsForSale[nftContract].length - pageBegin);
            }

            if (pageSize > 0) {   
                tokenInfos = new LTypes.SellNFT[] (pageSize);
                for (uint256 i = pageBegin; i < pageBegin + pageSize; i++) {
                    tokenInfos[i - pageBegin] = 
                        _nftSales[nftContract][_nftIdsForSale[nftContract][i]];
                }
            }
        }
    }

    /// @notice get saling nft tokens from contract address
    /// @dev NFT buyers can get list of sale nfts using this function
    /// @param nftContract nft contract address
    /// @return nftTokenIds array of nft tokenIds
    function getTokensIdsOnSale(address nftContract) 
    external 
    view returns (uint256[] memory) {
        return _nftIdsForSale[nftContract];
    }

    /// @notice get details information about nft token sale from contract and tokenId
    /// @dev NFT buyers can get information about the nft token sale using this function
    /// @param nftContract NFT contract address
    /// @param tokenId NFT token id for getting information
    /// @return nftSaleInfo filled with SellNFT structure object
    function getTokenSaleInfo(address nftContract, uint256 tokenId) 
    external 
    view returns (LTypes.SellNFT memory) {
        return _nftSales[nftContract][tokenId];
    }

    /// @notice get auction nft tokens array from contract address
    /// @dev NFT bidders can get list of auction nfts using this function
    /// @param nftContract nft contract address
    /// @param pageBegin begin index of pagenation
    /// @param pageSize size of pagenation
    /// @return tokenInfos nftToken Info's array of nft tokenIds
    function getTokenInfosOnAuction(address nftContract, uint256 pageBegin, uint256 pageSize) 
    external 
    view returns (LTypes.AuctionNFT[] memory tokenInfos) {
        if (pageBegin < _nftIdsForAuction[nftContract].length) {
            if (pageSize > _nftIdsForAuction[nftContract].length - pageBegin) {
                pageSize = (_nftIdsForAuction[nftContract].length - pageBegin);
            }

            if (pageSize > 0) {
                tokenInfos = new LTypes.AuctionNFT[] (pageSize);
                for (uint256 i = pageBegin; i < pageBegin + pageSize; i++) {
                    tokenInfos[i - pageBegin] = 
                        _nftAuctions[nftContract][_nftIdsForAuction[nftContract][i]];
                }
            }
        }
    }

    /// @notice get auction nft tokens from contract address
    /// @dev NFT bidders can get list of auction nfts using this function
    /// @param nftContract nft contract address
    /// @return nftTokenIds array of nft tokenIds
    function getTokenIdsOnAuction(address nftContract) 
    external 
    view returns (uint256[] memory) {
        return _nftIdsForAuction[nftContract];
    }

    /// @notice get details information about nft token auction from contract and tokenId
    /// @dev NFT bidders can get information about the nft token auction using this function
    /// @param nftContract NFT contract address
    /// @param tokenId NFT token id for getting information
    /// @return nftAuctionInfo filled with AuctionNFT structure object
    function getTokenAuctionInfo(address nftContract, uint256 tokenId) 
    external 
    view returns (LTypes.AuctionNFT memory) {
        return _nftAuctions[nftContract][tokenId];
    }

    /// @notice buy one nft token from progressing sale
    /// @dev NFT buyers can purchase nft token from sales using this function
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for buying
    function buyNFT(address nftContract, uint256 tokenId) 
    external 
    payable
    nonReentrant
    onlySale(nftContract, tokenId)
    onlyNotTokenOwner(nftContract, tokenId) {
        uint256 amount = _nftSales[nftContract][tokenId].price;
        address seller = _nftSales[nftContract][tokenId].seller;
        address erc20Token = _nftSales[nftContract][tokenId].erc20Token;
        uint256 toTreasury = amount * feeToTreasury / 100;
        uint256 toSeller = amount - toTreasury;
        _resetSale(nftContract, tokenId);

        if (erc20Token == address(0)) {
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
            if (!IERC20(erc20Token).transferFrom(msg.sender, seller, toSeller)) 
                revert NFTEngineERC20TransferFailed(erc20Token, amount);

            if (!IERC20(erc20Token).transferFrom(msg.sender, _treasury, toTreasury)) 
                revert NFTEngineERC20TransferFailed(erc20Token, amount);
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

    function mintNFT(address erc20, uint256 price, uint256 royalty, string memory uri) 
    external {        
        // IERC721Mock(_nftContract).safeMint(msg.sender, uri);
    }
    
    function nftOwner(address nftContract, uint256 tokenId) 
    external 
    view returns (address) {
        return IERC721(nftContract).ownerOf(tokenId);       
    }

    /// @notice Setup parameters applicable to all auctions and whitelised sales:
    /// @param nftContract NFT collection's contract address
    /// @param tokenId NFT token id for auction
    /// @param erc20Token ERC20 Token for payment (if specified by the seller)
    /// @param minPrice minimum price
    /// @param buyNowPrice buy now price
    /// @param feeRecipients fee recipients addresses
    /// @param feeRates respective fee percentages for each recipients    
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

        _nftIdsForAuction[nftContract].push(tokenId);
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

    /// @notice Make bids with ETH or an ERC20 Token specified by the NFT seller.*
    /// Additionally, a buyer can pay the asking price to conclude a sale*
    /// of an NFT.       
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

    /// @notice Check if a bid has been made. This is applicable in the early bid scenario
    /// to ensure that if an auction is created after an early bid, the auction
    /// begins appropriately or is settled if the buy now price is met.
    function _isAlreadyBidMade(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        return (_nftAuctions[nftContract][tokenId].highestBid > 0);
    }

    /// @notice If the minPrice is set by the seller, check that the highest bid meets or exceeds that price.
    function _isMinimumBidMade(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 minPrice = _nftAuctions[nftContract][tokenId].minPrice;
        return ( minPrice > 0 &&
            (_nftAuctions[nftContract][tokenId].highestBid >= minPrice));
    }

    /// @notice If the buy now price is set by the seller, check that the highest bid meets that price.
    function _isBuyNowPriceMet(address nftContract, uint256 tokenId)
    internal
    view returns (bool)
    {
        uint128 buyNowPrice = _nftAuctions[nftContract][tokenId].buyNowPrice;
        return (buyNowPrice > 0 &&
            _nftAuctions[nftContract][tokenId].highestBid >= buyNowPrice);
    }

    /// @notice Check that a bid is applicable for the purchase of the NFT.
    /// In the case of a sale: the bid needs to meet the buyNowPrice.
    /// In the case of an auction: the bid needs to be a % higher than the previous bid.
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

    /// @notice Returns the percentage of the total bid (used to calculate fee payments)
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

    /// @notice The default value for the NFT recipient is the highest bidder.
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

    /// @notice Settle an auction or sale if the buyNowPrice is met or set
    /// auction period to begin if the minimum price has been met.
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
            _updateAuctionEnd(nftContract, tokenId);
            _transferNftToAuctionContract(nftContract, tokenId, nftSeller);
        }
    }

    function _transferNftToAuctionContract(address nftContract, uint256 tokenId, address nftSeller) 
    internal {
        if (IERC721(nftContract).ownerOf(tokenId) == nftSeller) {
            IERC721(nftContract).safeTransferFrom(
                nftSeller,
                address(this),
                tokenId
            );
        } 
        if (IERC721(nftContract).ownerOf(tokenId) != address(this))
            revert NFTEngineTokenTransferFailed(nftContract, tokenId);
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
        _resetAuction(nftContract, tokenId);

        _payFeesAndSeller(
            nftContract,
            tokenId,
            nftSeller,
            nftHighestBid
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

    function _payFeesAndSeller(
        address nftContract,
        uint256 tokenId,
        address nftSeller,
        uint256 highestBid
    ) internal {
        uint256 toTreasury = highestBid * feeToTreasury / 100;
        highestBid = highestBid - toTreasury;

        _payout(
            nftContract,
            tokenId,
            _treasury,
            toTreasury
        );

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
            if (!IERC20(auctionERC20Token).transfer(recipient, amount)) {
                revert NFTEngineERC20TransferFailed(auctionERC20Token, amount);
            }
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

    /// @notice Reset all sale related parameters for an NFT.
    /// This effectively removes an EFT as an item up for sale
    function _resetSale(address nftContract, uint256 tokenId) 
    internal {
        removeNftIdFromSells(nftContract, tokenId);
    }

    /// @notice Reset all auction related parameters for an NFT.
    /// This effectively removes an EFT as an item up for auction
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
            if (!IERC20(auctionERC20Token).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            )) {
                revert NFTEngineERC20TransferFailed(auctionERC20Token, tokenAmount);
            }
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