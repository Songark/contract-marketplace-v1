//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC721Mock {
    
    function safeMint(address to, string memory uri) external;
    
}