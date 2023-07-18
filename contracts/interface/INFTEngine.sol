//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///@title Interface for the NFT Marketplace Engine
///@notice {INFTEngine} is the interface inherited by {NFTEngine}
interface INFTEngine {
    
    /// @dev when owner set the nft contract address on marketplace, this event would be emitted.
    /// @param nftType nft contract's type
    /// @param nftContract nft contract's address
    event NFTContractUpdated(
        uint256 nftType,
        address indexed nftContract
    );

    /// @dev when owner set the payment contract address on marketplace, this event would be emitted.
    /// @param payType type of payment token
    /// @param paymentContract payment contract address
    event PaymentContractUpdated(
        uint256 payType,
        address indexed paymentContract
    );

    /// @dev when owner creates sale using his NFT token on marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param from seller's address
    /// @param payType payment type
    /// @param price nft's price for sale
    event NFTTokenSaleCreated(
        address indexed nftContract, 
        uint256 tokenId, 
        address indexed from, 
        uint256 payType,
        uint256 price
    );

    /// @dev when user canceled an NFT token sale from marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    event NFTTokenSaleWithdrawn(
        address indexed nftContract, 
        uint256 tokenId
    );

    /// @dev when user bought an NFT token from marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token id
    /// @param to buyer's address
    event NFTTokenSaleClosed(
        address indexed nftContract, 
        uint256 tokenId, 
        address indexed to
    );

    /// @dev when owner creates auction using his NFT token on marketplace, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param seller nft owner's address
    /// @param minPrice minimum price of auction
    /// @param buyNowPrice maximum price of auction, if someone will bid with buyNoPrice, this auction will end immediately
    /// @param auctionBidPeriod valid period's seconds of auction, where someone can bid and purchase NFTs
    event NFTAuctionCreated(
        address indexed nftContract,
        uint256 tokenId,
        address indexed seller,
        uint256 payType,
        uint256 minPrice,
        uint256 buyNowPrice,
        uint256 auctionBidPeriod
    );

    /// @dev when someone makes a bid in the auction of a special NFT, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param bidder address of offer to buy an NFT from the auction at a specific price.
    /// @param payType payment type
    /// @param tokenAmount offered price with ERC20 token amount
    event NFTAuctionBidMade(
        address indexed nftContract,
        uint256 tokenId,
        address indexed bidder,
        uint256 payType,
        uint256 tokenAmount
    );

    /// @dev when a bidder withdraw own bid from the auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param highestBidder address of highest bidder in this auction
    event NFTAuctionBidWithdrawn(
        address indexed nftContract,
        uint256 tokenId,
        address indexed highestBidder
    );

    /// @dev when someone bid on this action at first time, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param auctionEndPeriod end timestamp of valid period for this auction
    event NFTAuctionUpdated(
        address indexed nftContract,
        uint256 tokenId,
        uint256 auctionEndPeriod
    );

    /// @dev when the NFT will be sold to someone in this auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param seller  nft old owner's address
    /// @param highestBid highest bid price in this auction
    /// @param highestBidder address of highest bidder in this auction
    /// @param buyer  nft new owner's address
    event NFTAuctionPaid(
        address indexed nftContract,
        uint256 tokenId,
        address indexed seller,
        uint256 highestBid,
        address indexed highestBidder,
        address buyer
    );

    /// @dev when the owner of NFT auction requests settlement to complete this auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param settler  nft old owner's address
    event NFTAuctionSettled(
        address indexed nftContract,
        uint256 tokenId,
        address indexed settler
    );

    /// @dev when the owner of NFT auction requests withdrawal to cancel this auction, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    event NFTAuctionWithdrawn(
        address indexed nftContract,
        uint256 tokenId
    );

    /// @dev when the owner of NFT auction requests to update minPrice, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param newMinPrice new value of minPrice
    event NFTAuctionMinPriceUpdated(
        address indexed nftContract,
        uint256 tokenId,
        uint256 newMinPrice
    );

    /// @dev when the owner of NFT auction requests to update buyNowPrie, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    /// @param newBuyNowPrice new value of buyNowPrice
    event NFTAuctionBuyNowPriceUpdated(
        address indexed nftContract,
        uint256 tokenId,
        uint128 newBuyNowPrice
    );

    /// @dev when the NFT seller ends an auction by taking the current highest bid, this event would be emitted.
    /// @param nftContract nft contract's address
    /// @param tokenId nft token's id
    event NFTAuctionHighestBidTaken(
        address indexed nftContract, 
        uint256 tokenId
    );

    /// @dev when need to pay fiat USD to the NFT seller, this event would be emitted.
    /// @param nftSeller nft seller's address
    /// @param price USD price balance
    event NFTPayFiatToSeller(
        address indexed nftSeller,
        uint256 price
    );
}