# PlayEstates NFT Marketplace v1

Smart contracts that allow the flexible auction and sell, buy of NFTs.


This repository contains the smart contracts source code of the full featured NFT Marketplace for PlayEstates. 
The repository uses Hardhat as development enviroment for compilation, testing and deployment tasks.

## NFT Marketplace functionality work

The open source smart contract can be easily used in a permissionless and flexible manner to auction (or simply buy/sell) NFTs. Sellers and bidders are able to make customized auctions and bids that allow for a holistic NFT auction/sale mechanism.

## NFT sellers' features:
- Create an sale for their single NFT and customize their sell option by specifying the following:
  - The accepted payment type (ETH or any ERC20 token)
  - The fee receivers and rates as array
  - The token id for their single NFT
  - Create an sale by calling createSale function

## NFT buyers' features:
- Get all token sales and buy an NFT by specifying the following:
  - Get all token ids by calling getTokensOnSale function
  - Get a token's detail by calling getTokenSaleInfo function
  - Buy an NFT by calling buyNFT function with token id
    
## NFT auction users' features:

## Development