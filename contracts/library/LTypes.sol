//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LTypes {

    /// @dev 4 types available nft contract
    enum NFTTypes {
        customNFT, 
        fractionalNFT,
        membershipNFT,
        owndNFT
    } 

    /// @dev 4 actions in marketplace
    enum Action {
        MINT,
        BUY,
        SELL,
        AUCTION
    }

    /// @dev mint nft request structure
    struct MintNFT {
        uint256 price;
    }

    /// @dev sell nft request structure
    struct SellNFT {
        uint256 tokenId;
        address erc20Token;
        address seller;
        uint256 price;        
        address[] feeRecipients;
        uint32[] feeRates;
    }

    /// @dev auction nft request structure
    struct AuctionNFT {
        uint256 tokenId;
        uint32 bidIncRate;
        uint32 bidPeriod; 
        uint64 endTime;
        uint128 minPrice;
        uint128 buyNowPrice;
        uint128 highestBid;
        address highestBidder;
        address seller;
        address whitelistedBuyer;
        address recipient;
        address erc20Token;
        bool isOnSale;
        address[] feeRecipients;
        uint32[] feeRates;
    }
    
}