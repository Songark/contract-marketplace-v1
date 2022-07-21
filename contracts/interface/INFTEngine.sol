//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface INFTEngine {

    /// @notice when owner creates sale using his NFT token on marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    /// @param from seller address
    /// @param erc20Token payment token address
    /// @param price nft's price for sale
    event NFTTokenSaleCreated(address nftContract, uint256 tokenId, address from, address erc20Token, uint256 price);

    /// @notice when user canceled an NFT token sale from marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    event NFTTokenSaleCanceled(address nftContract, uint256 tokenId);

    /// @notice when user bought an NFT token from marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    /// @param to buyer address
    event NFTTokenSaleClosed(address nftContract, uint256 tokenId, address to);


}