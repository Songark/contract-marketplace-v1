//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///@title Interface for the NFT Marketplace Factory
///@notice {INFTEngineFactory} is the interface inherited by {NFTEngineFactory}
interface INFTEngineFactory {
    
    ///@dev when a marketplace engine is created successfully, this event would be emit.
    ///@param nftEngine address of new created marketplace engine 
    event NFTEngineCreated(address indexed nftEngine);
    
    ///@dev create a marketplace engine, and then emit the event NFTEngineCreated with created engine's address
    ///@notice check more details about parameters and return value, in {NFTEngineFactory::createNFTEngine}
    function createNFTEngine(address admin, address treasury) external;

    ///@dev get a marketplace engine's address from administrator's address
    ///@notice check more details about parameters and return value, in {NFTEngineFactory::getNftEngineByAdmin}
    function getNftEngineByAdmin(address admin) external view returns (address);
}