// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./engine/NFTEngine.sol";
import "./interface/INFTEngineFactory.sol";

///@title NFT Marketplace Engine Factory for PlayEstates
///@dev NFTEngineFactory is used to create marketplace engines with different administrators.
contract NFTEngineFactory is INFTEngineFactory {
    
    ///@dev mapping of administrator vs marketplace engine address, key is the address of administrator
    ///@notice An administrator can have only one marketplace engine
    mapping(address => address) nftEngines;

    constructor() {

    }

    ///@notice Inherit from INFTEngineFactory
    ///@dev create a marketplace engine, and then emit the event NFTEngineCreated with created engine's address
    ///@param admin address of administrator who can manage the created marketplace engine
    ///@param treasury address of treasury for getting fee
    function createNFTEngine(address admin, address treasury) 
    external
    override {
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

    ///@notice Inherit from INFTEngineFactory
    ///@dev get a marketplace engine's address from administrator's address
    ///@param admin address of administrator who can manage the created marketplace engine
    ///@return nftEngine marketplace engine's address owned by admin
    function getNftEngineByAdmin(address admin) 
    external 
    override view returns (address) {
        return nftEngines[admin];
    }

}