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
### NFT sellers can perform the following actions to auction their NFTs:
- Create an auction for their single NFT and customize their auction
- Create a default auction, which accepts all of the above parameters except for the bid increase percentage and auction bid period. These values are defaulted to the following
- Create a sale for a single NFT by specifying the following for each sale
### NFT bidders can perform the following actions using Marketplace contract:
- Make a bid on an NFT put up for auction by specifying
- Purchase an NFT put up for sale by specifying

## Development
### Build, deploy and test
```shell
npx hardhat clean
npx hardhat compile
npx hardhat test
```