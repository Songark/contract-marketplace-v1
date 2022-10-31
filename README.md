# PlayEstates NFT Marketplace v1

Smart contracts that allow the flexible auction and sell, buy of NFTs.

This repository contains the smart contracts source code of the full featured NFT Marketplace for PlayEstates. 
The repository uses Hardhat as development enviroment for compilation, testing and deployment tasks.

If you want to learn about the core concepts and engineering structure of the marketplace engine, please explore developer's documents in the /docs/en folder, you can understand about smart contracts and test scripts.

You can see the class diagram [link](classDiagram.svg) for smart contracts to understand the structure.

For smart contract audit, [This](docs/audit/Preparation.md) provides all types of technical and functional requirements documentation.

## NFT Marketplace functionality work

These smart contracts can be easily used in a permissionless and flexible manner to auction (or simply buy/sell) NFTs. Sellers and bidders are able to make customized auctions and bids that allow for a holistic NFT auction/sale mechanism.

## NFT sellers' features:
- Create a sale for their single NFT and customize their sell option by specifying the following:
  - The accepted payment type (ERC20 token named PBRT Token)
  - The fee receivers and rates as array
  - The token id for their single NFT
  - Create an sale by calling createSale function
- Create batch sale for their a number of NFTs and customize their sell option

## NFT buyers' features:
- Get all token sales and buy an NFT by specifying the following:
  - Get all token ids by calling getTokensOnSale function
  - Get a token's detail by calling getTokenSaleInfo function
  - Buy an NFT by calling buyNFT function with token id
    
## NFT auction users' features:
### NFT sellers can perform the following actions to auction their NFTs:
- Create an auction for their single NFT and customize their auction
  - The accepted payment type (ERC20 token named PBRT Token)
  - The minimum price of the auction (when this is met, the auction begins and users have a specific time to make a subsequent higher bid). If the buy now price is also set, the minimum price cannot be greater than 80% of the price.
  - A buy now price, which when met by a buyer will automatically conclude the auction. The seller can set this value to zero, in which case the auction will only end when the minimum price is met and the auction bid period has concluded.
  - The auction bid period, which specifies the amount of time the auction will last after the minimum price is met. Every time a higher bid is then met, the auction will continue again for this time.
  - A bid increase percentage (specified in basis points of 10000), which determines the amount a bidder must deposit in order to become the highest bidder. Therefore, if a bid of X amount is made, the next bidder must make a bid of X + ((X*bid increase percentage)/10000).
  - An array of fee recipient addresses who will receive a percentage of the selling price of an auction when the auction is concluded.
  - An array of fee percentages (each in basis points of 10000) which must match the number of fee recipients. This determines the split of the selling price for each fee recipient.
- Create a default auction, which accepts all of the above parameters except for the bid increase percentage and auction bid period. These values are defaulted to the following
- Withdraw their auction if the minimum price of the auction has not yet been met, or at anytime when put up for sale as long as the buy now price has not yet been met (in this case, the seller would not be the owner of the NFT as it would be tranferred to the highest bidder).
- Update the minimum price of the auction. This can only be done if no bid has been made that already exceeds the original minimum price. The new minimum price is still limited to 80% of the buy now price if set. if an underbid has been made on the auction, and this update would mean that the minimum price is met by that underbid, then the auction would begin.
- Update the buy now price of the auction or sale. In the case of an auction the buy now price cannot be set to an amount which would make the minimum price greater than 80% of the buy now price. If a bid has been made on an auction or sale, and this update would mean that this bid now meets the buy now price, then the auction or sale would be concluded and the NFT and bid amount would be distributed accordingly.
- Take the highest bid amount and conclude the auction or sale.
### NFT bidders can perform the following actions using Marketplace contract:
- Make a bid on an NFT put up for auction by specifying
  - The amount of the bid (in either ETH or PBRT Token as specified by the NFT seller). The bidder must make a bid that is higher by the bid increase percentage if another bid has already been made. 
  - However if this is met the bidder does not have to make a bid higher than the minimum price set by the seller (in this case, the auction would not start). Therefore, if no bid has been made on auction, the bidder can specify any amount.
- Purchase an NFT put up for sale by specifying
  - The amount of PBRT Token or ETH (as specified by the seller). In this scenario, the purchaser can make an underbid of the buy now price, which will not conclude the sale. The amount sent by the bidder must then be the default percentage higher than the previous underbid. If the bidder specifies an amount equal to or greater than the buy now price, the sale is concluded and the NFT and purchase amount are transferred.
- Withdraw their bid on auction or sale if the minimum price of the auction has not been met, or in the case of an underbid on a sale.
- In the case of an auction where the auction bid period has expired (where the minimum bid has been met). Then any user can settle the auction and distribute the bid and NFT to the respective seller and recipient.
- In the case where the distribution of a bid amount has failed, the recipient of that amount can reclaim their failed credits.

## Development
### Build, deploy, test this project
```shell
npx hardhat clean
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deployTokensAndEngine.js [--network goerli | rinkeby]
```

### Update NFT contracts ** Pay attension about the NFT contracts address in the updateNfts.js **
```shell
npx hardhat run scripts/updateNfts.js [--network goerli | rinkeby]
```

### Code coverage and generate the documents
```shell
npx hardhat coverage  
npm run docgen
```

### Generate the class diagram
```shell
sol2uml ./contracts
```
