# Preparations for PlayEstates NFT Marketplace v1 Smart Contracts

## Functionality requirements
This smart contract can be easily used in a permissionless and flexible manner to buy/sell/auction NFTs. Sellers, buyers, and bidders can make customized auctions and sales, and also bids that allow for a holistic NFT auction/sale mechanism.
There are only two types of NFT contracts available to this contract; MembershipNFT and CustomNFT.
There are only two types of payment options available in this contract; ETH and PlayEstatesBrickToken erc20 tokens.
Total trades' payment should be divided into treasury's fee (5%) and customer's receivers fee (95% will be divided by parameters).

## NFT sale features:
- Create a sale for their single NFT and customize their sell option by specifying the following:
  - The token contract and id for their single NFT
  - The accepted payment type (ETH or ERC20 token named PBRT)
  - The fee receivers and rates as array
  - Create a sale by calling the "createSale" function
- Withdraw the created sale by calling the "withdrawSale" if not sold.

## NFT buyers' features:
- Get all token sales and buy an NFT by specifying the following:
  - Get all saling token ids by calling the "getTokenInfosOnSale" function
  - Get saling token's detail by calling the "getTokenSaleInfo" function
  - Buy NFT token by calling the "buyNFT" function with token contract, id and enough ETH or PBRT approved tokens
    
## NFT auction features:
### NFT sellers can perform the following actions to auction their NFTs:
- Create an auction for their single NFT and customize their auction by calling the "createAuction" function
  - The accepted payment type (ETH or ERC20 token named PBRT)
  - The minimum price of the auction (when this is met, the auction begins and users have a specific time to make a subsequent higher bid). If the buy now price is also set, the minimum price cannot be greater than 80% of the price.
  - A buy now price, which when met by a buyer will automatically conclude the auction. The seller can set this value to zero, in which case the auction will only end when the minimum price is met and the auction bid period has concluded.
  - The auction bid period, which specifies the amount of time the auction will last after the minimum price is met. Every time a higher bid is then met, the auction will continue again for this time.
  - A bid increase percentage (specified in basis points of 10000), which determines the amount a bidder must deposit in order to become the highest bidder. Therefore, if a bid of X amount is made, the next bidder must make a bid of X + ((X*bid increase percentage)/10000).
  - An array of fee recipient addresses who will receive a percentage of the selling price of an auction when the auction is concluded.
  - An array of fee percentages (each in basis points of 10000) which must match the number of fee recipients. This determines the split of the selling price for each fee recipient.
- Withdraw their auction by calling the "withdrawAuction" function in the case of following condition
  - if the minimum price of the auction has not yet been met, or at anytime when put up for sale as long as the buy now price has not yet been met (in this case, the seller would not be the owner of the NFT as it would be tranferred to the highest bidder).
- Update the minimum price of the auction. This can only be done if no bid has been made that already exceeds the original minimum price. The new minimum price is still limited to 80% of the buy now price if set. if an underbid has been made on the auction, and this update would mean that the minimum price is met by that underbid, then the auction would begin.
- Update the buy now price of the auction or sale. In the case of an auction the buy now price cannot be set to an amount which would make the minimum price greater than 80% of the buy now price. If a bid has been made on an auction or sale, and this update would mean that this bid now meets the buy now price, then the auction or sale would be concluded and the NFT and bid amount would be distributed accordingly.
- Take the highest bid amount and conclude the auction by calling the "takeHighestBid" function.
### NFT bidders can perform the following actions using Marketplace contract:
- Make a bid on an NFT put up for auction by specifying (calling the "makeBid" function)
  - The amount of the bid (in either ETH or PBRT Token as specified by the NFT seller). The bidder must make a bid that is higher by the bid increase percentage if another bid has already been made. 
  - However if this is met the bidder does not have to make a bid higher than the minimum price set by the seller (in this case, the auction would not start). Therefore, if no bid has been made on auction, the bidder can specify any amount.  
- Purchase an NFT put up for sale by specifying
  - The amount of PBRT Token or ETH (as specified by the seller). In this scenario, the purchaser can make an underbid of the buy now price, which will not conclude the sale. The amount sent by the bidder must then be the default percentage higher than the previous underbid. If the bidder specifies an amount equal to or greater than the buy now price, the sale is concluded and the NFT and purchase amount are transferred.
- Withdraw their bid on auction or sale if the minimum price of the auction has not been met, or in the case of an underbid on a sale, by calling the "withdrawBid" function
- In the case of an auction where the auction bid period has expired (where the minimum bid has been met). Then any user can settle the auction and distribute the bid and NFT to the respective seller and recipient.
- In the case where the distribution of a bid amount has failed, the recipient of that amount can reclaim their failed credits.
- Get all auctioning token ids by calling the "getTokenInfosOnAuction" function
- Get auctioning token's detail by calling the "getTokenAuctionInfo" function

## Technical description
### Programming languages
- Solidity version 0.8.4
- Javascript, Typescript
### Technologies
- Hardhat platform for building, testing, and deploying this project
  - Hardhat configuration
  - Hardhat plugins for checking contract size and used gas cost
  - hardhat-contract-sizer, hardhat-gas-reporter
- ERC721Psi advanced protocol for saving gas cost using batch minting
- ERC20 protocol for payment option tokens
- ReentrancyGuardUpgradeable for preventing attacks
- Upgradable context and Clone feature for optimizing contract size
- Custom Error for saving gas cost
- Token locking, Role processing
- Solidity-coverage for testing all features, functions, and codes
- Solidity-docgen for generating full documentation about source codes
- Sol2uml for generating the class diagram automatically
### Deployment instructions
- Deploy Marketplace Engine, Membership/Custom NFT, and PBRT Token contracts
    ```shell
    npx hardhat clean
    npx hardhat compile    
    npx hardhat run scripts/deployTokensAndEngine.js [--network goerli | rinkeby]
    ```
- In order to deploy on other chains like polygon main or mumbai, please config additional information on the hardhat.config.js file.
### Test instructions
#### Unit test
- Test pretty much features of the Marketplace Engine, Membership/Custom NFT, and PBRT Token contracts
    ```shell
    npx hardhat clean
    npx hardhat compile    
    npx hardhat test
    ```
- There are about 30 test cases for the positive and negative testing scenarios 
#### Goerli network test
- Already tested on the Goerli network using these deployed contracts and frontend
  - Marketplace Engine contract
    https://goerli.etherscan.io/address/0x878b6eE9784A6a08BAdc18c140C19C36bdb6e4A7
  - Membership NFT contract
    https://goerli.etherscan.io/address/0xc08BA1198fA68aA12BBa73C1c5b3FCB6243cbe6a
  - PBRT Token contract
    https://goerli.etherscan.io/address/0xb1677C5639CC483267cC720833d09e0ABd10000A
  - Custom NFT contract
    https://goerli.etherscan.io/address/0xCBDC5Eb81AF6c156c49341C2B12b998849992463
