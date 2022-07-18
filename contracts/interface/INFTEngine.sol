//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface INFTEngine {

    /// @notice when user buy an NFT token from marketplace, this event would be emit.
    /// @param nftContract nft contract address
    /// @param tokenId nft token id
    /// @param from seller address
    /// @param to buyer address
    /// @param price nft price for sale
    event NFTTokenSold(address nftContract, uint256 tokenId, address from, address to, uint256 price);
}