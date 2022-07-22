//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IERC721AMock.sol";

contract ERC721AMock is ERC721A, IERC721AMock, Ownable {

    address public contractMarket;

    modifier onlyMarketplace() {
        require(msg.sender == contractMarket, "Only allowed from Marketplace");
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC721A(name_, symbol_)
    {}

    function safeMint(address to, uint256 quantity, uint8 tierIndex)
    external
    override onlyMarketplace {
        _safeMint(to, quantity);
    }

    function setMarketplace(address marketplace) 
    public
    onlyOwner {
        require(marketplace != address(0), "Invalid marketplace address");
        contractMarket = marketplace;
    }

}
