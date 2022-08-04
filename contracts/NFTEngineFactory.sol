// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./engine/NFTEngine.sol";

contract NFTEngineFactory {

    event NFTEngineCreated(address nftEngine);
    
    mapping(address => address) nftEngines;

    constructor() {

    }

    function createNFTEngine(address nftContract, address treasury) external {
        require(nftEngines[nftContract] == address(0), "Already engine created");

        NFTEngine _engine = new NFTEngine();
        _engine.initialize(msg.sender, nftContract, treasury);
        address newEngine = address(_engine);

        nftEngines[nftContract] = newEngine;

        emit NFTEngineCreated(newEngine);
    }

    function upgradeNFTEngine(address nftContract, address treasury) external {

    }

    function getNftEngineByContract(address nftContract) 
    external 
    view returns (address) {
        return nftEngines[nftContract];
    }

}