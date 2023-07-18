// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721psi/ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Helper we wrote to encode in Base64
import "@openzeppelin/contracts/utils/Base64.sol";
import "solidity-bits/contracts/BitMaps.sol";

contract PlayEstatesTokenization is ERC721Psi, Ownable {

    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    event Burn(address indexed account, uint256 tokenId);
    event Locked(address indexed owner, bool locked);
    event TradingAllowed(address indexed owner, bool tradingAllowed);
    event UpdateTierInfo(string tierName, uint256 tierTokenValue, uint256 tierPercent);

    error URIQueryForNonexistentToken();
    
    struct TierProp  {
        string name;
        uint256 percent;
        uint256 value;
        string image; // image
        string ext_url; // external_url
        string ani_url; // animation_url
    }

    BitMaps.BitMap private _burnedToken;
    // A modifier to lock/unlock token transfer
    bool public locked;
    bool public tradingAllowed;
    address public nftPoolAddress;
    uint256 public maxOwnLimit = 2;

    TierProp public tierInfo;

    constructor(string memory name_, string memory symbol_, address poolAddress_, uint256 supply_)
        ERC721Psi(name_, symbol_)
    {
        require(poolAddress_ != address(0), "invalid address");
        require(supply_ != 0, "invalid supply");
        nftPoolAddress = poolAddress_;
        _safeMint(nftPoolAddress, supply_);
    }

    modifier notLocked() {
        require(!locked, "GenesisOwnerKey: can't operate - currently locked");
        _;
    }

    function _startTokenId() internal pure virtual override returns (uint256) {
        return 1;
    }

    function updateTierInfo(
        string calldata tierName_,
        uint256 tierTokenValue_,
        uint256 tierPercent_,
        string calldata tierImageUri_,
        string calldata tierAnimationUri_,
        string calldata tierExternalUri_
    ) external onlyOwner {

        tierInfo = TierProp({
            name : tierName_,
            value : tierTokenValue_,
            percent : tierPercent_,
            image : tierImageUri_,
            ani_url : tierAnimationUri_,
            ext_url :  tierExternalUri_
        });
        emit UpdateTierInfo(tierName_, tierTokenValue_, tierPercent_);
    }

    // ---------------------------------------
    // -          External Functions         -
    // ---------------------------------------
    function toggleLock() external onlyOwner {
        locked = !locked;
        emit Locked(msg.sender, locked);
    }

    function toggleTradingAllowed() external onlyOwner {
        tradingAllowed = !tradingAllowed;
        emit TradingAllowed(msg.sender, tradingAllowed);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        emit Burn(_msgSender(), tokenId);
    }

    // ---------------------------------------
    // -          Internal Functions         -
    // ---------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function setMaxOwnLimit(uint256 _maxLimit) public onlyOwner {
        maxOwnLimit = _maxLimit;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256, /*startTokenId*/
        uint256 quantity
    ) internal virtual override {
        require(!locked, "locked");

        // Checking sender side
        if (from == address(0)) {
            // if minting, then return
            return;
        }
        // Checking receiver
        if (to == address(0)) {
            //if burning, then return
            return;
        }
        if (from == nftPoolAddress) {
            if (to != nftPoolAddress) {
                require(
                    balanceOf(to) + quantity <= maxOwnLimit,
                    "exceeded amount"
                );
            }
        } else {
            if (to != nftPoolAddress) {
                require(
                    tradingAllowed,
                    "trading coming soon"
                );
                require(
                    balanceOf(to) + quantity <= maxOwnLimit,
                    "exceeded amount"
                );
            }
        }
    }

    // ---------------------------------------
    // -          Burn Features          -
    // ---------------------------------------

    // for Burn
   /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        
        emit Transfer(from, address(0), tokenId);

        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view override virtual returns (bool){
        if(_burnedToken.get(tokenId)) {
            return false;
        } 
        return super._exists(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _minted - _burned();
    }

    /**
     * @dev Returns number of token burned.
     */
    function _burned() internal view returns (uint256 burned){
        uint256 totalBucket = (_minted >> 8) + 1;

        for(uint256 i=0; i < totalBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
    }

    /**
     * @dev Returns number of set bits.
     */
    function _popcount(uint256 x) private pure returns (uint256 count) {
        unchecked{
            for (count=0; x!=0; count++)
                x &= x - 1;
        }
    }
}