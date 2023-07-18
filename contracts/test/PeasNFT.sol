// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../library/Base64.sol";
import "../erc721psi/ERC721Psi.sol";
import "../interface/IPeasNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solidity-bits/contracts/BitMaps.sol";

contract PeasNFT is ERC721Psi, IPeasNFT, Ownable {
    
    error PeasNFT_CurrentLocked();

    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;

    string public baseURI;  
    bool private _locked;
    address private _treasury;

    constructor(string memory name_, string memory symbol_) 
        ERC721Psi(name_, symbol_) {
        
        _locked = true;
        baseURI = "https://playestates.mypinata.cloud/ipfs/QmSzaRSHQ6yeYPe7oR2umyACF84otR2DwCmTUX4Lrrgv9c";
    }

    function setTreasury(address treasury)
    external 
    onlyOwner {
        require(treasury != address(0), "Invalid treasury");
        _treasury = treasury;
    }

    function mint(address to, uint256 quantity) 
    external 
    onlyOwner {
        _safeMint(to, quantity);
        emit Mint(_msgSender(), to, quantity);
    }

    function burn(uint256 tokenId) 
    external {
        require(msg.sender == ownerOf(tokenId), "Not allowed with no owner");

        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }


    function setBaseURI(string memory _newBaseURI) 
    public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    virtual override view returns (string memory)
    {
        if (!_exists(tokenId)) 
            revert URIQueryForNonexistentToken();

        string memory strTokenId = Strings.toString(tokenId);
        string memory s1 = string(
            abi.encodePacked(
                '{"id": ',
                strTokenId,
                ', "name": "',
                name(),
                ' #',
                strTokenId,
                '", "image": "',
                baseURI,
                '"'
            )
        );
        string memory s2 = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        s1,
                        ', "description": "PlayEstates Arcade Station NFT"}'                        
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", s2)
        );
        return output;
    }

    function totalSupply() 
    public 
    virtual override view returns (uint256) {
        return _minted - _burned();
    }

    function unlock()
    public 
    onlyOwner {
        _locked = false;
    }

    function lock()
    public 
    onlyOwner {
        _locked = true;
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) 
    internal 
    override view {        
        if (from != address(0) && from != _treasury) {
            require(!_locked, "PEAS nft is locked");
        }
    }

    function _burn(uint256 tokenId) 
    internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        
        emit Transfer(from, address(0), tokenId);

        _afterTokenTransfers(from, address(0), tokenId, 1);
    }
    
    function _burned() 
    internal 
    view returns (uint256 burned){
        uint256 totalBucket = (_minted >> 8) + 1;

        for(uint256 i=0; i < totalBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
    }

    function _popcount(uint256 x) 
    private 
    pure returns (uint256 count) {
        unchecked{
            for (count=0; x!=0; count++)
                x &= x - 1;
        }
    }

    function _exists(uint256 tokenId) 
    internal 
    override virtual view returns (bool){
        if(_burnedToken.get(tokenId)) {
            return false;
        } 
        return super._exists(tokenId);
    }

    function _baseURI() 
    internal 
    override virtual view returns (string memory) {
        return baseURI;
    }
}