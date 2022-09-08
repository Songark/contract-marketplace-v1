// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721psi/contracts/ERC721Psi.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MembershipNFTMock is ERC721Psi, Ownable {
    constructor(string memory name_, string memory symbol_) 
        ERC721Psi(name_, symbol_) {}

    function mint(address to, uint256 quantity) 
    external 
    onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId. (same as ERC721A)
        _safeMint(to, quantity);
    }
}