# NFTEngine

> NFTEngine is used to create sales & auctions and manage them effectively for seller,  buyers and bidders.

## 1.Contents
Name: NFT Marketplace Engine for PlayEstates
<p>
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| feeToTreasury | uint256 |
| defaultBidIncRate | uint32 |
| minSettableIncRate | uint32 |
| maxMinPriceRate | uint32 |
| defaultAuctionBidPeriod | uint32 |

## 3.Modifiers
### onlyValidPrice



*Declaration:*
```solidity
modifier onlyValidPrice
```


### onlyNotSale



*Declaration:*
```solidity
modifier onlyNotSale
```


### onlySale



*Declaration:*
```solidity
modifier onlySale
```


### onlyAuctionSeller



*Declaration:*
```solidity
modifier onlyAuctionSeller
```


### onlyNotAuctionSeller



*Declaration:*
```solidity
modifier onlyNotAuctionSeller
```


### onlyTokenOwner



*Declaration:*
```solidity
modifier onlyTokenOwner
```


### onlyApprovedToken



*Declaration:*
```solidity
modifier onlyApprovedToken
```


### onlyNotTokenOwner



*Declaration:*
```solidity
modifier onlyNotTokenOwner
```


### minPriceNotExceedLimit



*Declaration:*
```solidity
modifier minPriceNotExceedLimit
```


### checkSizeRecipientsAndRates



*Declaration:*
```solidity
modifier checkSizeRecipientsAndRates
```


### checkFeeRatesLessThanMaximum



*Declaration:*
```solidity
modifier checkFeeRatesLessThanMaximum
```


### auctionOngoing



*Declaration:*
```solidity
modifier auctionOngoing
```


### onlyApplicableBuyer



*Declaration:*
```solidity
modifier onlyApplicableBuyer
```


### onlyPaymentAcceptable



*Declaration:*
```solidity
modifier onlyPaymentAcceptable
```



## 4.Functions

### initialize



*Declaration:*
```solidity
function initialize(
) public initializer
```
*Modifiers:*
| Modifier |
| --- |
| initializer |




### setNFTContracts



*Declaration:*
```solidity
function setNFTContracts(
) external
```




### removeNftIdFromSells



*Declaration:*
```solidity
function removeNftIdFromSells(
) internal
```




### removeNftIdFromAuctions



*Declaration:*
```solidity
function removeNftIdFromAuctions(
) internal
```




### changeTreasury



*Declaration:*
```solidity
function changeTreasury(
) external onlyOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlyOwner |




### createAuction
Setup parameters applicable to all auctions and whitelised sales:
     @param nftContract NFT collection's contract address
     @param tokenId NFT token id for auction
     @param erc20Token ERC20 Token for payment (if specified by the seller)
     @param minPrice minimum price
     @param buyNowPrice buy now price
     @param feeRecipients The fee recipients addresses
     @param feeRates their respective percentages for a sucessful auction/sale


*Declaration:*
```solidity
function createAuction(
) external
```




### settleAuction



*Declaration:*
```solidity
function settleAuction(
) external
```




### withdrawAuction



*Declaration:*
```solidity
function withdrawAuction(
) external
```




### takeHighestBid



*Declaration:*
```solidity
function takeHighestBid(
) external onlyAuctionSeller
```
*Modifiers:*
| Modifier |
| --- |
| onlyAuctionSeller |




### makeBid



*Declaration:*
```solidity
function makeBid(
) external auctionOngoing onlyApplicableBuyer
```
*Modifiers:*
| Modifier |
| --- |
| auctionOngoing |
| onlyApplicableBuyer |




### withdrawBid



*Declaration:*
```solidity
function withdrawBid(
) external
```




### createSale



*Declaration:*
```solidity
function createSale(
) external onlyTokenOwner onlyApprovedToken onlyValidPrice onlyNotSale
```
*Modifiers:*
| Modifier |
| --- |
| onlyTokenOwner |
| onlyApprovedToken |
| onlyValidPrice |
| onlyNotSale |




### withdrawSale



*Declaration:*
```solidity
function withdrawSale(
) external onlyTokenOwner onlySale
```
*Modifiers:*
| Modifier |
| --- |
| onlyTokenOwner |
| onlySale |




### getNFTContract



*Declaration:*
```solidity
function getNFTContract(
) external returns
(address)
```




### getTokensOnSale



*Declaration:*
```solidity
function getTokensOnSale(
) external returns
(uint256[])
```




### getTokenSaleInfo



*Declaration:*
```solidity
function getTokenSaleInfo(
) external returns
(struct LTypes.SellNFT)
```




### getTokensOnAuction



*Declaration:*
```solidity
function getTokensOnAuction(
) external returns
(uint256[])
```




### getTokenAuctionInfo



*Declaration:*
```solidity
function getTokenAuctionInfo(
) external returns
(struct LTypes.AuctionNFT)
```




### buyNFT



*Declaration:*
```solidity
function buyNFT(
) external onlySale onlyNotTokenOwner
```
*Modifiers:*
| Modifier |
| --- |
| onlySale |
| onlyNotTokenOwner |




### mintNFT



*Declaration:*
```solidity
function mintNFT(
) external
```




### nftOwner



*Declaration:*
```solidity
function nftOwner(
) external returns
(address)
```




### _setupAuction



*Declaration:*
```solidity
function _setupAuction(
) internal minPriceNotExceedLimit checkSizeRecipientsAndRates checkFeeRatesLessThanMaximum
```
*Modifiers:*
| Modifier |
| --- |
| minPriceNotExceedLimit |
| checkSizeRecipientsAndRates |
| checkFeeRatesLessThanMaximum |




### _isAuctionOngoing



*Declaration:*
```solidity
function _isAuctionOngoing(
) internal returns
(bool)
```




### _makeBid



*Declaration:*
```solidity
function _makeBid(
) internal onlyNotAuctionSeller onlyPaymentAcceptable
```
*Modifiers:*
| Modifier |
| --- |
| onlyNotAuctionSeller |
| onlyPaymentAcceptable |




### _isAlreadyBidMade



*Declaration:*
```solidity
function _isAlreadyBidMade(
) internal returns
(bool)
```




### _isMinimumBidMade



*Declaration:*
```solidity
function _isMinimumBidMade(
) internal returns
(bool)
```




### _isBuyNowPriceMet



*Declaration:*
```solidity
function _isBuyNowPriceMet(
) internal returns
(bool)
```




### _doesBidMeetBidRequirements
Check that a bid is applicable for the purchase of the NFT.
In the case of a sale: the bid needs to meet the buyNowPrice.
In the case of an auction: the bid needs to be a % higher than the previous bid.


*Declaration:*
```solidity
function _doesBidMeetBidRequirements(
) internal returns
(bool)
```




### _getPortionOfBid



*Declaration:*
```solidity
function _getPortionOfBid(
) internal returns
(uint256)
```




### _getAuctionBidPeriod



*Declaration:*
```solidity
function _getAuctionBidPeriod(
) internal returns
(uint32)
```




### _getNftRecipient



*Declaration:*
```solidity
function _getNftRecipient(
) internal returns
(address)
```




### _getBidIncreasePercentage



*Declaration:*
```solidity
function _getBidIncreasePercentage(
) internal returns
(uint32)
```




### _updateOngoingAuction



*Declaration:*
```solidity
function _updateOngoingAuction(
) internal
```




### _transferNftToAuctionContract



*Declaration:*
```solidity
function _transferNftToAuctionContract(
) internal
```




### _transferNftAndPaySeller



*Declaration:*
```solidity
function _transferNftAndPaySeller(
) internal
```




### _payFeesAndSeller



*Declaration:*
```solidity
function _payFeesAndSeller(
) internal
```




### _payout



*Declaration:*
```solidity
function _payout(
) internal
```




### _isPaymentAccepted



*Declaration:*
```solidity
function _isPaymentAccepted(
) internal returns
(bool)
```




### _isERC20Auction



*Declaration:*
```solidity
function _isERC20Auction(
) internal returns
(bool)
```




### _updateAuctionEnd



*Declaration:*
```solidity
function _updateAuctionEnd(
) internal
```




### _resetSale



*Declaration:*
```solidity
function _resetSale(
) internal
```




### _resetAuction



*Declaration:*
```solidity
function _resetAuction(
) internal
```




### _resetBids



*Declaration:*
```solidity
function _resetBids(
) internal
```




### _isWhitelistedAuction



*Declaration:*
```solidity
function _isWhitelistedAuction(
) internal returns
(bool)
```




### _updateHighestBid



*Declaration:*
```solidity
function _updateHighestBid(
) internal
```




### _reverseAndResetPreviousBid



*Declaration:*
```solidity
function _reverseAndResetPreviousBid(
) internal
```




### _reversePreviousBidAndUpdateHighestBid



*Declaration:*
```solidity
function _reversePreviousBidAndUpdateHighestBid(
) internal
```




## 5.Events
