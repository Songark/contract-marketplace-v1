//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///@title Interface for the NFT Marketplace Engine
///@notice {INFTEngine} is the interface inherited by {NFTEngine}
interface INFTEngine {

    /// @dev when owner creates sale using his NFT token on marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param from seller's address
    /// @param erc20Token ERC20 token's address for payment, if address(0), seller needs payment using ether
    /// @param price nft's price for sale
    event NFTTokenSaleCreated(
        address nftContract, 
        uint256 tokenId, 
        address from, 
        address erc20Token, 
        uint256 price
    );

    /// @dev when user canceled an NFT token sale from marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    event NFTTokenSaleWithdrawn(
        address nftContract, 
        uint256 tokenId
    );

    /// @dev when user bought an NFT token from marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token id
    /// @param to buyer's address
    event NFTTokenSaleClosed(
        address nftContract, 
        uint256 tokenId, 
        address to
    );

    /// @dev when owner creates auction using his NFT token on marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param seller nft owner's address
    /// @param erc20Token ERC20 token's address for payment, if address(0), seller needs payment using ether
    /// @param minPrice minimum price of auction
    /// @param buyNowPrice maximum price of auction, if someone will bid with buyNoPrice, this auction will end immediately
    /// @param auctionBidPeriod valid period's seconds of auction, where someone can bid and purchase NFTs
    /// @param bidIncRate bid increment for next bid request, valid value is between 0 and 10000
    event NFTAuctionCreated(
        address nftContract,
        uint256 tokenId,
        address seller,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncRate
    );

    /// @dev when someone makes a bid in the auction of a special NFT, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param bidder address of offer to buy an NFT from the auction at a specific price.
    /// @param ethAmount offered price with ether
    /// @param erc20Token ERC20 token's address for payment
    /// @param tokenAmount offered price with ERC20 token amount
    event NFTAuctionBidMade(
        address nftContract,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount,
        address erc20Token,
        uint256 tokenAmount
    );

    /// @dev when a bidder withdraw own bid from the auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param highestBidder address of highest bidder in this auction
    event NFTAuctionBidWithdrawn(
        address nftContract,
        uint256 tokenId,
        address highestBidder
    );

    /// @dev when someone bid on this action at first time, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param auctionEndPeriod end timestamp of valid period for this auction
    event NFTAuctionUpdated(
        address nftContract,
        uint256 tokenId,
        uint64 auctionEndPeriod
    );

    /// @dev when the NFT will be sold to someone in this auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param seller  nft old owner's address
    /// @param highestBid highest bid price in this auction
    /// @param highestBidder address of highest bidder in this auction
    /// @param buyer  nft new owner's address
    event NFTAuctionPaid(
        address nftContract,
        uint256 tokenId,
        address seller,
        uint128 highestBid,
        address highestBidder,
        address buyer
    );

    /// @dev when the owner of NFT auction requests settlement to complete this auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param settler  nft old owner's address
    event NFTAuctionSettled(
        address nftContract,
        uint256 tokenId,
        address settler
    );

    /// @dev when the owner of NFT auction requests withdrawal to cancel this auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    event NFTAuctionWithdrawn(
        address nftContract,
        uint256 tokenId
    );

    /// @dev when the owner of NFT auction requests to update minPrice, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param newMinPrice new value of minPrice
    event NFTAuctionMinPriceUpdated(
        address nftContract,
        uint256 tokenId,
        uint256 newMinPrice
    );

    /// @dev when the owner of NFT auction requests to update buyNowPrie, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param newBuyNowPrice new value of buyNowPrice
    event NFTAuctionBuyNowPriceUpdated(
        address nftContract,
        uint256 tokenId,
        uint128 newBuyNowPrice
    );

    /// @dev when the NFT seller ends an auction by taking the current highest bid, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    event NFTAuctionHighestBidTaken(
        address nftContract, 
        uint256 tokenId
    );
}