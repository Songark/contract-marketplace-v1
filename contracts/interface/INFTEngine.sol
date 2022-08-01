//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface INFTEngine {

    /// @notice when owner creates sale using his NFT token on marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    /// @param from seller address
    /// @param erc20Token payment token address
    /// @param price nft's price for sale
    event NFTTokenSaleCreated(
        address nftContract, 
        uint256 tokenId, 
        address from, 
        address erc20Token, 
        uint256 price
    );

    /// @notice when user canceled an NFT token sale from marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    event NFTTokenSaleCanceled(
        address nftContract, 
        uint256 tokenId
    );

    /// @notice when user bought an NFT token from marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    /// @param to buyer address
    event NFTTokenSaleClosed(
        address nftContract, 
        uint256 tokenId, 
        address to
    );

    event NFTAuctionCreated(
        address nftContract,
        uint256 tokenId,
        address seller,
        address erc20Token,
        uint128 minPrice,
        uint128 buyNowPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncRate,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event NFTAuctionBidMade(
        address nftContract,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount,
        address erc20Token,
        uint256 tokenAmount
    );

    event NFTAuctionBidWithdrawn(
        address nftContract,
        uint256 tokenId,
        address highestBidder
    );

    event NFTAuctionUpdated(
        address nftContract,
        uint256 tokenId,
        uint64 auctionEndPeriod
    );

    event NFTAuctionPaid(
        address nftContractAddress,
        uint256 tokenId,
        address seller,
        uint128 highestBid,
        address highestBidder,
        address buyer
    );

    event NFTAuctionSettled(
        address nftContract,
        uint256 tokenId,
        address settler
    );

    event NFTAuctionWithdrawn(
        address nftContract,
        uint256 tokenId,
        address tokenOwner
    );

    event NFTAuctionMinPriceUpdated(
        address nftContract,
        uint256 tokenId,
        uint256 newMinPrice
    );

    event NFTAuctionBuyNowPriceUpdated(
        address nftContract,
        uint256 tokenId,
        uint128 newBuyNowPrice
    );

    event NFTAuctionHighestBidTaken(
        address nftContract, 
        uint256 tokenId
    );
}