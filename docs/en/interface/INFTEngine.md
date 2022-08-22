# INFTEngine



## 1.Contents
Name: Interface for the NFT Marketplace Engine
<p>
<!-- START doctoc -->
<!-- END doctoc -->

## 2.Globals

## 3.Modifiers

## 4.Functions

## 5.Events
### NFTTokenSaleCreated

> when owner creates sale using his NFT token on marketplace, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`from` | address |  | seller's address
|`erc20Token` | address |  | ERC20 token's address for payment, if address(0), seller needs payment using ether
|`price` | uint256 |  | nft's price for sale
### NFTTokenSaleWithdrawn

> when user canceled an NFT token sale from marketplace, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
### NFTTokenSaleClosed

> when user bought an NFT token from marketplace, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token id
|`to` | address |  | buyer's address
### NFTAuctionCreated

> when owner creates auction using his NFT token on marketplace, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`seller` | address |  | nft owner's address
|`erc20Token` | address |  | ERC20 token's address for payment, if address(0), seller needs payment using ether
|`minPrice` | uint128 |  | minimum price of auction
|`buyNowPrice` | uint128 |  | maximum price of auction, if someone will bid with buyNoPrice, this auction will end immediately
|`auctionBidPeriod` | uint32 |  | valid period's seconds of auction, where someone can bid and purchase NFTs
|`bidIncRate` | uint32 |  | bid increment for next bid request, valid value is between 0 and 10000
### NFTAuctionBidMade

> when someone makes a bid in the auction of a special NFT, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`bidder` | address |  | address of offer to buy an NFT from the auction at a specific price.
|`ethAmount` | uint256 |  | offered price with ether
|`erc20Token` | address |  | ERC20 token's address for payment
|`tokenAmount` | uint256 |  | offered price with ERC20 token amount
### NFTAuctionBidWithdrawn

> when a bidder withdraw own bid from the auction, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`highestBidder` | address |  | address of highest bidder in this auction
### NFTAuctionUpdated

> when someone bid on this action at first time, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`auctionEndPeriod` | uint64 |  | end timestamp of valid period for this auction
### NFTAuctionPaid

> when the NFT will be sold to someone in this auction, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`seller` | address |  |  nft old owner's address
|`highestBid` | uint128 |  | highest bid price in this auction
|`highestBidder` | address |  | address of highest bidder in this auction
|`buyer` | address |  |  nft new owner's address
### NFTAuctionSettled

> when the owner of NFT auction requests settlement to complete this auction, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`settler` | address |  |  nft old owner's address
### NFTAuctionWithdrawn

> when the owner of NFT auction requests withdrawal to cancel this auction, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
### NFTAuctionMinPriceUpdated

> when the owner of NFT auction requests to update minPrice, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`newMinPrice` | uint256 |  | new value of minPrice
### NFTAuctionBuyNowPriceUpdated

> when the owner of NFT auction requests to update buyNowPrie, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
|`newBuyNowPrice` | uint128 |  | new value of buyNowPrie
### NFTAuctionHighestBidTaken

> when the NFT seller ends an auction by taking the current highest bid, this event would be emitted.



*Params:*
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nftContract` | address |  | nft contract's address
|`tokenId` | uint256 |  | nft token's id
