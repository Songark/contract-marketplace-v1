//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC721AMock {

    function safeMint(address to, uint256 quantity, uint8 tierIndex) external;
    
}