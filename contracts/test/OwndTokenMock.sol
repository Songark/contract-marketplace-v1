//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OwndTokenMock is ERC20 {
    constructor() ERC20("OWNED", "OWND") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
