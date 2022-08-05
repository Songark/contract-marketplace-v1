//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICustomNFTMock {
    
    function safeMint(address to, string memory uri) external;
    
}