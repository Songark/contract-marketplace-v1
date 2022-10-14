# NFTEngineV1

> NFTEngineV1 is used to create sales & auctions and manage them effectively for seller,  buyers and bidders.

## 1.Contents
Name: NFT Marketplace Engine for PlayEstates
<p>
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Variables

| Arg | Type | Description |
| --- | --- | --- |
feeToTreasury | uint256 | 
defaultBidIncRate | uint32 | 
minSettableIncRate | uint32 | 
maxMinPriceRate | uint32 | 
defaultAuctionBidPeriod | uint32 | 

## 3.Modifiers
### onlyValidPrice

> Throws if called with invalid price

*Declaration:*
```solidity
modifier onlyValidPrice
```


### onlySale

> Throws if called with not saling nft token id

*Declaration:*
```solidity
modifier onlySale
```


### onlyAuctionSeller

> Throws if called by invalid seller of the auction

*Declaration:*
```solidity
modifier onlyAuctionSeller
```


### onlySaleSeller

> Throws if called by invalid seller of the sale

*Declaration:*
```solidity
modifier onlySaleSeller
```


### onlyNotAuctionSeller

> Throws if called by seller of the auction

*Declaration:*
```solidity
modifier onlyNotAuctionSeller
```


### onlyNotSaleSeller

> Throws if called by seller of the sale

*Declaration:*
```solidity
modifier onlyNotSaleSeller
```


### onlyTokenOwner

> Throws if called by invalid nft token owner

*Declaration:*
```solidity
modifier onlyTokenOwner
```


### onlyApprovedToken

> Throws if nft token is not approved by marketplace

*Declaration:*
```solidity
modifier onlyApprovedToken
```


### checkSizeRecipientsAndRates

> Throws if called with different length of recipients and rates

*Declaration:*
```solidity
modifier checkSizeRecipientsAndRates
```


### checkFeeRatesLessThanMaximum

> Throws if called with invalid fee rates, sum of fee rates is smaller than 10000

*Declaration:*
```solidity
modifier checkFeeRatesLessThanMaximum
```


### auctionOngoing

> Throws if called with not on-going auction

*Declaration:*
```solidity
modifier auctionOngoing
```



## 4.Functions

### initialize

> See {NFTEngineFactory-createNFTEngine} for more infos about params, initializer for upgradable


*Declaration:*
```solidity
function initialize(
address admin,
address treasury
) external initializer
```
*Modifiers:*
| Modifier |
| --- |
| initializer |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`admin` | address | address of administrator who can manage the created marketplace engine
|`treasury` | address | address of treasury for getting fee


### onERC721Received

> Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
by `operator` from `from`, this function is called.
It must return its Solidity selector to confirm the token transfer.
If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.

*Declaration:*
```solidity
function onERC721Received(
) external returns
(bytes4)
```




### setNFTContract
Set nft contracts address to the marketplace engine

> marketplace engine will use these 4 types of nft contracts for sales and auctions


*Declaration:*
```solidity
function setNFTContract(
uint256 nftType,
address nftContract
) external onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftType` | uint256 | type of nft contracts, between 0 and 3
|`nftContract` | address | address of nft contract contract


### setPaymentContract
Set erc20 token contract address to the marketplace engine

> marketplace engine will use this erc20 token for payment option


*Declaration:*
```solidity
function setPaymentContract(
address paymentToken
) external onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`paymentToken` | address | address of erc20 token contract


### getContractAddress
Get nft or erc20 contract address from type

> everyone can get one of 4 types nft contracts using this function


*Declaration:*
```solidity
function getContractAddress(
uint256 tokenType
) external returns
(address)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`tokenType` | uint256 | see the enum values {LTypes::TokenTypes}

*Returns:*
| Arg | Description |
| --- | --- |
|`nftContract` | nft contract address

### removeNftIdFromSells
Remove token id from sales list

> marketplace engine will call this function after finishing sale


*Declaration:*
```solidity
function removeNftIdFromSells(
address nftContract,
uint256 nftId
) internal
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`nftId` | uint256 | NFT token id


### removeNftIdFromAuctions
Remove token id from auctions list

> marketplace engine will call this function after finishing auction


*Declaration:*
```solidity
function removeNftIdFromAuctions(
address nftContract,
uint256 nftId
) internal
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`nftId` | uint256 | NFT token id


### changeTreasury
Change treasury address by owner

> marketplace engine owner can use this function to change treasury


*Declaration:*
```solidity
function changeTreasury(
address newTreasury
) external onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`newTreasury` | address | address of new treasury


### createAuction
Create an auction request with parameters

> NFT owners can create auctions using this function


*Declaration:*
```solidity
function createAuction(
address nftContract,
uint256 tokenId,
address erc20Token,
uint128 minPrice,
uint128 buyNowPrice,
uint256 bidPeriod,
address[] feeRecipients,
uint32[] feeRates
) external nonReentrant
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for auction
|`erc20Token` | address | ERC20 Token for payment (if specified by the seller)
|`minPrice` | uint128 | minimum price
|`buyNowPrice` | uint128 | buy now price
|`bidPeriod` | uint256 | bid period seconds
|`feeRecipients` | address[] | fee recipients addresses
|`feeRates` | uint32[] | respective fee percentages for each recipients


### settleAuction
Settle progressing auction for nft token

> NFT auction creators can settle their auctions using this function


*Declaration:*
```solidity
function settleAuction(
address nftContract,
uint256 tokenId
) external nonReentrant auctionOngoing
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| auctionOngoing |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for settle auction


### withdrawAuction
Withdraw progressing auction for nft token

> NFT auction creators can withdraw their auctions using this function


*Declaration:*
```solidity
function withdrawAuction(
address nftContract,
uint256 tokenId
) external nonReentrant onlyTokenOwner
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| onlyTokenOwner |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for withdraw auction


### takeHighestBid
Complete progressing auction with current highest bid

> NFT auction creators can complete their auctions using this function


*Declaration:*
```solidity
function takeHighestBid(
address nftContract,
uint256 tokenId
) external nonReentrant onlyAuctionSeller
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| onlyAuctionSeller |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for complete auction


### makeBid
Make a bid request for on going auction with payment parameters

> NFT bidders can make a bid on the specific auction using this function


*Declaration:*
```solidity
function makeBid(
address nftContract,
uint256 tokenId,
address erc20Token,
uint128 amount
) external nonReentrant onlyNotAuctionSeller auctionOngoing
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| onlyNotAuctionSeller |
| auctionOngoing |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for making bid
|`erc20Token` | address | ERC20 token for payment (if specified by the seller)
|`amount` | uint128 | ERC20 token amount for payment


### _makeBid
Make a bid request for on going auction with payment parameters

> internal function for makeBid() external


*Declaration:*
```solidity
function _makeBid(
address nftContract,
uint256 tokenId,
address erc20Token,
uint128 tokenAmount
) internal
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for making bid
|`erc20Token` | address | ERC20 token for payment (if specified by the seller)
|`tokenAmount` | uint128 | ERC20 token amount for payment


### withdrawBid
Withdraw own bid from on going auction

> NFT bidders can withdraw their bid on the specific auction using this function


*Declaration:*
```solidity
function withdrawBid(
address nftContract,
uint256 tokenId
) external nonReentrant
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for making bid


### createSale
Create an sale request with parameters

> NFT owners can create sales using this function


*Declaration:*
```solidity
function createSale(
address nftContract,
uint256 tokenId,
address erc20Token,
uint128 sellPrice,
address[] feeRecipients,
uint32[] feeRates
) external nonReentrant onlyTokenOwner onlyApprovedToken onlyValidPrice
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| onlyTokenOwner |
| onlyApprovedToken |
| onlyValidPrice |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for auction
|`erc20Token` | address | ERC20 Token for payment (if specified by the seller)
|`sellPrice` | uint128 | sell price
|`feeRecipients` | address[] | fee recipients addresses
|`feeRates` | uint32[] | respective fee percentages for each recipients


### _createSale
Create an sale request with parameters

> internal function for createSale() external


*Declaration:*
```solidity
function _createSale(
address nftContract,
uint256 tokenId,
address erc20Token,
uint128 sellPrice,
address[] feeRecipients,
uint32[] feeRates
) internal
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for auction
|`erc20Token` | address | ERC20 Token for payment (if specified by the seller)
|`sellPrice` | uint128 | sell price
|`feeRecipients` | address[] | fee recipients addresses
|`feeRates` | uint32[] | respective fee percentages for each recipients


### withdrawSale
Withdraw a progressing sale for nft token

> NFT sellers can withdraw their sale using this function


*Declaration:*
```solidity
function withdrawSale(
address nftContract,
uint256 tokenId
) external nonReentrant onlySaleSeller
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| onlySaleSeller |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for withdraw sale


### getTokenInfosOnSale
Get saling nft tokens array from contract address

> NFT buyers can get list of sale nfts using this function


*Declaration:*
```solidity
function getTokenInfosOnSale(
address nftContract
) external returns
(struct LTypes.SellNFT[] tokenInfos)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | nft contract address

*Returns:*
| Arg | Description |
| --- | --- |
|`tokenInfos` | nftToken Info's array of nft tokenIds

### getTokenSaleInfo
Get details information about nft token sale from contract and tokenId

> NFT buyers can get information about the nft token sale using this function


*Declaration:*
```solidity
function getTokenSaleInfo(
address nftContract,
uint256 tokenId
) external onlySale returns
(struct LTypes.SellNFT)
```
*Modifiers:*
| Modifier |
| --- |
| onlySale |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT contract address
|`tokenId` | uint256 | NFT token id for getting information

*Returns:*
| Arg | Description |
| --- | --- |
|`nftSaleInfo` | filled with SellNFT structure object

### getTokenInfosOnAuction
Get auction nft tokens array from contract address

> NFT bidders can get list of auction nfts using this function


*Declaration:*
```solidity
function getTokenInfosOnAuction(
address nftContract
) external returns
(struct LTypes.AuctionNFT[] tokenInfos)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | nft contract address

*Returns:*
| Arg | Description |
| --- | --- |
|`tokenInfos` | nftToken Info's array of nft tokenIds

### getTokenAuctionInfo
Get details information about nft token auction from contract and tokenId

> NFT bidders can get information about the nft token auction using this function


*Declaration:*
```solidity
function getTokenAuctionInfo(
address nftContract,
uint256 tokenId
) external returns
(struct LTypes.AuctionNFT)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT contract address
|`tokenId` | uint256 | NFT token id for getting information

*Returns:*
| Arg | Description |
| --- | --- |
|`nftAuctionInfo` | filled with AuctionNFT structure object

### buyNFT
Buy one nft token from progressing sale

> NFT buyers can purchase nft token from sales using this function


*Declaration:*
```solidity
function buyNFT(
address nftContract,
uint256 tokenId
) external nonReentrant onlySale onlyNotSaleSeller
```
*Modifiers:*
| Modifier |
| --- |
| nonReentrant |
| onlySale |
| onlyNotSaleSeller |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for buying


### _setupAuction
Setup parameters applicable to all auctions and whitelised sales:



*Declaration:*
```solidity
function _setupAuction(
address nftContract,
uint256 tokenId,
address erc20Token,
uint128 minPrice,
uint128 buyNowPrice,
uint256 bidPeriod,
address[] feeRecipients,
uint32[] feeRates
) internal checkSizeRecipientsAndRates checkFeeRatesLessThanMaximum
```
*Modifiers:*
| Modifier |
| --- |
| checkSizeRecipientsAndRates |
| checkFeeRatesLessThanMaximum |

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for auction
|`erc20Token` | address | ERC20 Token for payment (if specified by the seller)
|`minPrice` | uint128 | minimum price
|`buyNowPrice` | uint128 | buy now price
|`bidPeriod` | uint256 | bid period seconds
|`feeRecipients` | address[] | fee recipients addresses
|`feeRates` | uint32[] | respective fee percentages for each recipients


### _isAuctionOngoing
Checking the auction's status. 

> If the Auction's endTime is set to 0, the auction is technically on-going, 
however the minimum bid price (minPrice) has not yet been met.   


*Declaration:*
```solidity
function _isAuctionOngoing(
address nftContract,
uint256 tokenId
) internal returns
(bool)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id for auction


### _isAlreadyBidMade
Check if a bid has been made. This is applicable in the early bid scenario
to ensure that if an auction is created after an early bid, the auction
begins appropriately or is settled if the buy now price is met.



*Declaration:*
```solidity
function _isAlreadyBidMade(
address nftContract,
uint256 tokenId
) internal returns
(bool)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id


### _isMinimumBidMade
If the minPrice is set by the seller, check that the highest bid meets or exceeds that price.



*Declaration:*
```solidity
function _isMinimumBidMade(
address nftContract,
uint256 tokenId
) internal returns
(bool)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id


### _isBuyNowPriceMet
If the buy now price is set by the seller, check that the highest bid meets that price.



*Declaration:*
```solidity
function _isBuyNowPriceMet(
address nftContract,
uint256 tokenId
) internal returns
(bool)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id


### _doesBidMeetBidRequirements
Check that a bid is applicable for the purchase of the NFT.
In the case of a sale: the bid needs to meet the buyNowPrice.
In the case of an auction: the bid needs to be a % higher than the previous bid.



*Declaration:*
```solidity
function _doesBidMeetBidRequirements(
address nftContract,
uint256 tokenId,
uint128 tokenAmount
) internal returns
(bool)
```

*Args:*
| Arg | Type | Description |
| --- | --- | --- |
|`nftContract` | address | NFT collection's contract address
|`tokenId` | uint256 | NFT token id    
|`tokenAmount` | uint128 | erc20 token's amount


### _getPortionOfBid
Returns the percentage of the total bid (used to calculate fee payments)


*Declaration:*
```solidity
function _getPortionOfBid(
) internal returns
(uint256)
```




### _getAuctionBidPeriod
Returns the bid period of an auction from nft contract and token id


*Declaration:*
```solidity
function _getAuctionBidPeriod(
) internal returns
(uint32)
```




### _getNftRecipient
Returns the default value for the NFT recipient is the highest bidder.


*Declaration:*
```solidity
function _getNftRecipient(
) internal returns
(address)
```




### _getBidIncreasePercentage
Returns the increase percentage property of an auction from nft contract and token id


*Declaration:*
```solidity
function _getBidIncreasePercentage(
) internal returns
(uint32)
```




### _updateOngoingAuction
Settle an auction or sale if the buyNowPrice is met or set
auction period to begin if the minimum price has been met.


*Declaration:*
```solidity
function _updateOngoingAuction(
) internal
```




### _transferNftToAuctionContract
Transfers nft token to this marketplace contract


*Declaration:*
```solidity
function _transferNftToAuctionContract(
) internal
```




### _transferNftAndPaySeller
Pays the ethereum or erc20 to seller and transferring nft token to highest buyer,
clearing the auction request


*Declaration:*
```solidity
function _transferNftAndPaySeller(
) internal
```




### _payFeesAndSeller
Pays the fee to treasury and fee recipients, and then send the rest to seller


*Declaration:*
```solidity
function _payFeesAndSeller(
) internal
```




### _payout
Pays the specific amount of ethereum or erc20 tokens to the recipient wallet


*Declaration:*
```solidity
function _payout(
) internal
```




### _isPaymentAccepted
Payment is accepted in the following scenarios:
(1) Auction already created - can accept ETH or Specified Token
 --------> Cannot bid with ETH & an ERC20 Token together in any circumstance<------
(2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
(3) Cannot make a zero bid (no ETH or Token amount)


*Declaration:*
```solidity
function _isPaymentAccepted(
) internal returns
(bool)
```




### _isERC20Auction
Checks the erc20 token's address and return true if it's not zero.


*Declaration:*
```solidity
function _isERC20Auction(
) internal returns
(bool)
```




### _updateAuctionEnd
Increase the specific auction's end timestamp with the bid period seconds


*Declaration:*
```solidity
function _updateAuctionEnd(
) internal
```




### _resetSale
Reset all sale related parameters for an NFT.
this effectively removes an EFT as an item up for sale


*Declaration:*
```solidity
function _resetSale(
) internal
```




### _resetAuction
Reset all auction related parameters for an NFT.
This effectively removes an EFT as an item up for auction


*Declaration:*
```solidity
function _resetAuction(
) internal
```




### _resetBids
Reset all auction bids related parameters for an NFT.


*Declaration:*
```solidity
function _resetBids(
) internal
```




### _isWhitelistedAuction
Checks whether the specific auction has whitelisted buyers or not.


*Declaration:*
```solidity
function _isWhitelistedAuction(
) internal returns
(bool)
```




### _updateHighestBid
Updates the highest bidder and bid price for an Auction request


*Declaration:*
```solidity
function _updateHighestBid(
) internal
```




### _reversePreviousBidAndUpdateHighestBid
Reverse transfers the ethereum or erc20 token to the previous highest bidder 
and updating the new highest bidder with tokenAmount


*Declaration:*
```solidity
function _reversePreviousBidAndUpdateHighestBid(
) internal
```




## 5.Events

## 6.Structs

## 7.Enums
