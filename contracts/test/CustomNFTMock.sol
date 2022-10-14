// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract CustomNFTMock is ERC721, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function mint(address to, uint256 tokenId) 
    public onlyOwner {
        _safeMint(to, tokenId);
    }
}
