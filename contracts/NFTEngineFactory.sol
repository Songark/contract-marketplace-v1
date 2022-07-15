// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./engine/NFTEngine.sol";

contract NFTEngineFactory {
    
    mapping(address => address) nftEngines;

    mapping(address => address[]) ownEngines;

    constructor() {

    }

    function createNFTEngine(address nftContract) external {

        address newEngine = address(new NFTEngine(nftContract));

        nftEngines[nftContract] = newEngine;

        ownEngines[msg.sender].push(newEngine);
    }

    function getNftEngineByContract(address nftContract) 
    external 
    view returns (address) {
        return nftEngines[nftContract];
    }

}