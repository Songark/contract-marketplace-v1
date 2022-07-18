// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./engine/NFTEngine.sol";

contract NFTEngineFactory {

    event NFTEngineCreated(address nftEngine);
    
    mapping(address => address) nftEngines;

    mapping(address => address[]) ownEngines;

    constructor() {

    }

    function createNFTEngine(address nftContract, address treasury) external {
        require(nftEngines[nftContract] == address(0), "Already engine created");

        address newEngine = address(new NFTEngine(msg.sender, nftContract, treasury));
        nftEngines[nftContract] = newEngine;
        ownEngines[msg.sender].push(newEngine);

        emit NFTEngineCreated(newEngine);
    }

    function getNftEngineByContract(address nftContract) 
    external 
    view returns (address) {
        return nftEngines[nftContract];
    }

}