//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LTypes {

    /// @dev 4 types available nft contract
    enum NFTTypes {
        membershipNFT,  // OWNDK
        peasNFT,        // PEAS
        pnftSSNFT,      // PNFT - SS
        pnftSNFT,       // PNFT - S
        pnftANFT,       // PNFT - A
        pnftBNFT,       // PNFT - B
        pnftCNFT,       // PNFT - C
        customNFT
    } 

    /// @dev 4 types available payment tokens
    enum PayTypes {
        payAll,         // Anything 
        payEther,       // Ether / Matic
        payUSDC,        // USDC
        payPBRT,        // PBRT
        payFiat         // Fiat USD
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
        address seller;
        uint256 payType;
        uint256 price;        
    }

    /// @dev auction nft request structure
    struct AuctionNFT {
        uint256 tokenId;
        uint256 minPrice;
        uint256 buyNowPrice;
        uint256 bidPeriod; 
        uint256 endTime;
        uint256 payType; 
        uint256 highestBid;
        address highestBidder;
        address seller;
    }
}