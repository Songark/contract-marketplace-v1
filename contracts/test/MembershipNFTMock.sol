// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../library/Base64.sol";
import "../erc721psi/ERC721Psi.sol";
import "../interface/IMembershipNFTMock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "solidity-bits/contracts/BitMaps.sol";

contract MembershipNFTMock is ERC721Psi, IMembershipNFTMock, Ownable, ReentrancyGuard {
    
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;

    enum TokenType {
        Mogul,
        Investor
    }

    struct TokenMeta {
        uint256 tokenId;
        TokenType tokenType;
    }

    uint256 public constant SUPPLY_PER_TYPE = 10000;                 // total supply: 10000
    
    string public tierImageURI;  
    string public tierAnimationURL;  
    string[] public typeNames = ["Mogul", "Investor"];
    mapping (uint256 => TokenMeta) private _tokenMeta;
    mapping (TokenType => uint256) private _tokenTypes;

    modifier validTokenType(TokenType tokenType) {
        require(tokenType >= TokenType.Mogul && tokenType <= TokenType.Investor,
            "Invalid token type");
        _;
    }

    constructor(string memory name_, string memory symbol_) 
        ERC721Psi(name_, symbol_) {
        
        tierImageURI = "https://playestates.mypinata.cloud/ipfs/QmfRdaYxMmvxrBbEcp3yVz4TUwnQJmTmPnqc1tQhfKWoKF/";
        tierAnimationURL = "https://playestates.mypinata.cloud/ipfs/Qmb1krM5cm2GesmnX4MgTGdqiiPKU9Z5eviKLx5tqat7VV/";
    }

    function mint(address to, uint256 quantity, TokenType tokenType) 
    external 
    onlyOwner validTokenType(tokenType) {
        require(_tokenTypes[tokenType] + quantity <= SUPPLY_PER_TYPE, 
            "Overflow the totalsupply for the type");

        _safeMint(to, quantity);

        for (uint i = _minted; i > _minted - quantity; i--) {
            TokenMeta storage tokenMeta = _tokenMeta[i];
            tokenMeta.tokenId = i;
            tokenMeta.tokenType = tokenType;
        }
        _tokenTypes[tokenType] += quantity;

        emit Mint(_msgSender(), to, quantity);
    }

    function burn(uint256 tokenId) 
    external 
    onlyOwner {
        _tokenTypes[_tokenMeta[tokenId].tokenType]--;
        delete _tokenMeta[tokenId];

        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }


    function setImageURI(string memory imageURI) 
    public onlyOwner {
        tierImageURI = imageURI;
    }

    function setAnimationURI(string memory animationURI) 
    public onlyOwner {
        tierAnimationURL = animationURI;
    }

    function tokenURI(uint256 tokenId)
    public
    virtual override view returns (string memory)
    {
        if (!_exists(tokenId)) 
            revert URIQueryForNonexistentToken();

        TokenMeta memory tokenMeta = _tokenMeta[tokenId];
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
                tierImageURI,
                typeNames[uint256(tokenMeta.tokenType)],
                '.jpg", '
                '"animation_url": "',
                tierAnimationURL,
                typeNames[uint256(tokenMeta.tokenType)],
                '.mp4"'
            )
        );
        string memory s2 = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        s1,
                        ', "description": "PlayEstates Founding Member Token"',
                        ', "attributes": [',
                        '{ "trait_type": "ID", "value": "', strTokenId, '" }, ',
                        '{ "trait_type": "Tier", "value": "',
                        typeNames[uint256(tokenMeta.tokenType)],
                        '"}',
                        ']}'
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

    function getMintedPerType(TokenType tokenType)
    public 
    onlyOwner view returns (uint256) {
        return _tokenTypes[tokenType];
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

}