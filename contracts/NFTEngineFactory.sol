// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./engine/NFTEngine.sol";

contract NFTEngineFactory {

    event NFTEngineCreated(address nftEngine);
    
    mapping(address => address) nftEngines;

    constructor() {

    }

    function createNFTEngine(address admin, address treasury) external {
        require(admin != address(0), "Invalid admin address");
        require(nftEngines[admin] == address(0), "Already marketplace was created");

        NFTEngine _marketplace = new NFTEngine();
        _marketplace.initialize(admin, treasury);
        address newMarketplace = address(_marketplace);

        nftEngines[admin] = newMarketplace;

        emit NFTEngineCreated(newMarketplace);
    }

    function upgradeNFTEngine(address admin, address treasury) external {

    }

    function getNftEngineByAdmin(address admin) 
    external 
    view returns (address) {
        return nftEngines[admin];
    }

}