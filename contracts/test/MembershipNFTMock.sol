// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MembershipNFTMock is ERC721A, Ownable {
    constructor() ERC721A("Genesis Owner Key", "OWNK") {}

    function mint(address to, uint256 quantity) external payable onlyOwner {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(to, quantity);
    }
}