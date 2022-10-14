//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PlayEstatesBrickToken is ERC20, AccessControl {
    
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");
    bytes32 public constant CONTRACT_ROLE = bytes32("CONTRACT_ROLE");

    bool public locked;
    constructor(string memory symbol, string memory name) 
        ERC20(symbol, name) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        locked = true;
    }

    function mint(address to, uint256 amount) 
    public 
    onlyRole(MINTER_ROLE) {
        _mint(to, amount * 10 ** decimals());
    }

    function decimals() 
    public 
    view virtual override returns (uint8) {
        return 0;
    }

    function setGameEngine(address gameEngine)
    public 
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTRACT_ROLE, gameEngine);
    }

    function setMarketplaceEngine(address marketEngine)
    public 
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTRACT_ROLE, marketEngine);
    }

    function setMintRole(address minter) 
    public 
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
    }

    function clearMintRole(address minter) 
    public 
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }

    function setLock(bool flag)
    public 
    onlyRole(DEFAULT_ADMIN_ROLE) {
        locked = flag;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        if (amount == 0) {
            return;
        }

        if (from == address(0) || to == address(0)) {
            // case of mint or burn
            return;    
        }

        if (hasRole(CONTRACT_ROLE, from) || hasRole(CONTRACT_ROLE, to)) {
            // case of transfer from or to game engine | marketplace
            return;
        }

        if (hasRole(CONTRACT_ROLE, msg.sender)) {
            // case pf transfer by game engine | marketplace
            return;
        }

        require(!locked, "PBRT is locked between user wallets");
    }
}