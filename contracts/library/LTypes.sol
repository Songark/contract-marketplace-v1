//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library LTypes {

    enum Action {
        MINT,
        BUY,
        SELL,
        AUCTION
    }

    struct MintNFT {
        uint256 price;
    }

    struct SellNFT {
        address erc20Token;
        address seller;
        uint256 price;        
        address[] feeRecipients;
        uint32[] feeRates;
    }

    struct AuctionNFT {
        uint32 bidIncRate;
        uint32 bidPeriod; 
        uint64 endTime;
        uint128 minPrice;
        uint128 curPrice;
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