// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../library/Base64.sol";
import "../erc721psi/ERC721Psi.sol";
import "../interface/IPefpNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "solidity-bits/contracts/BitMaps.sol";

contract PefpNFT is ERC721Psi, IPefpNFT, Ownable {
    
    error PeasNFT_CurrentLocked();

    using BitMaps for BitMaps.BitMap;

    struct TokenProp {
        uint256 profile;
        uint256 gamescore;
        uint256 transaction;
        uint128 rarity;
        uint128 tierlevel;
    }

    mapping (uint256 => TokenProp) private _tokenProps;
    BitMaps.BitMap private _burnedToken;
    string public baseURI;  
    bool private _locked;
    uint256 public maxOwnLimit = 4;

    constructor(string memory name_, string memory symbol_) 
        ERC721Psi(name_, symbol_) {
        
        _locked = true;
        baseURI = "https://playestates.mypinata.cloud/ipfs/QmSzaRSHQ6yeYPe7oR2umyACF84otR2DwCmTUX4Lrrgv9c";
    }

    function mint(
        address to, 
        uint256 profile,
        uint256 gamescore, 
        uint256 transaction,
        uint128 rarity,
        uint128 tierlevel) 
    external 
    onlyOwner {
        uint256 tokenId = _minted;
        _safeMint(to, 1);

        TokenProp storage _tokenProp = _tokenProps[tokenId];
        _tokenProp.profile = profile;
        _tokenProp.gamescore = gamescore;
        _tokenProp.transaction = transaction;
        _tokenProp.rarity = rarity;
        _tokenProp.tierlevel = tierlevel;

        emit Mint(_msgSender(), to, tokenId);
    }

    function burn(uint256 tokenId) 
    external {
        require(msg.sender == ownerOf(tokenId), "only allowed by the owner");
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
                _tokenImageURI(tokenId),
                '"'
            )
        );
        string memory s2 = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        s1,
                        '", "description": "PlayEstates Founding Player Token"',
                        ', "attributes": [',
                        '{ "trait_type": "Tier", "value": "',
                        _tokenProps[tokenId].tierlevel,
                        '"},',
                        '{ "trait_type": "ID", "value": "',
                        strTokenId,
                        '"},',
                        '{ "display_type": "number", "trait_type": "Game Play", "value": ',
                        Strings.toString(_tokenProps[tokenId].gamescore),
                        "},",
                        '{ "display_type": "number", "trait_type": "Token Transaction", "value": ',
                        Strings.toString(_tokenProps[tokenId].transaction),
                        "}",
                        "]}"
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

    function setLimitation(uint _maxLimit) 
    public 
    onlyOwner{
        maxOwnLimit = _maxLimit;
    }

    function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) 
    internal 
    override view {        
        if (from != address(0) && to != address(0)) {
            require(!_locked, "token is locked");
            require(balanceOf(to) < maxOwnLimit, "overflow of max limitation");
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

    function _tokenImageURI(uint256 tokenId) 
    internal 
    view returns (string memory) {
        string memory strTokenId = Strings.toString(tokenId);
        string memory strTokenImage = string(
            abi.encodePacked(
                baseURI,
                strTokenId,
                '.png'
            )
        );

        return strTokenImage;
    }
}