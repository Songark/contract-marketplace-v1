// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interface/IERC721Mock.sol";

contract ERC721Mock is ERC721, ERC721URIStorage, Ownable, IERC721Mock {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address private _marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == _marketplace || msg.sender == owner(), 
            "Only allowed from Marketplace or owner");
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function safeMint(address to, string memory uri) 
    external 
    override onlyMarketplace {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setTokenURI(uint256 tokenId, string memory uri)
    public {
        _setTokenURI(tokenId, uri);
    }

    function setMarketplace(address marketplace) 
    public
    onlyOwner {
        require(marketplace != address(0), "Invalid marketplace address");
        _marketplace = marketplace;
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
