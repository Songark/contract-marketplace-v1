import { EvmChain } from '@moralisweb3/evm-utils';
import Moralis  from 'moralis';

export const chain = EvmChain.RINKEBY;
export const moralis_apikey = "7ppyBj1nGG2aydKjrga4UyBTSoj6enVAU0n25zcYLbnYFA4oA4Cn7h6fuYgKg3xw";
export const nftEngine = "0x009E6D5F57982a77C3cd5C312C7c128C545FeC4a"; //"0xCC57ddD4B4D666F8587E8dD21Ecb7C4b99c5b8C1"; 

export enum contractType {
    customNFT,
    fractionalNFT,
    membershipNFT,
    ownedToken
};

export const contractAddress: string[] = [
    "0x03aE8f87a2717F572F96356347E244092fE8d54f",   // customNFT
    "0xD55501Db4d166202eF94913F2e084768A4c03489",   // fractionalNFT
    "0x4C42242fCB875728B84dB5BAe7d68BdCEAAa279E",   // membershipNFT
    "0x5060bD449F6cDD81e98C4Fad3aA21282Add981f0"    // owned token
]

export enum paymentType {
    pay_eth,
    pay_erc20
}

export const infuraApiKey = "5c948ab130cc463a9f712ecde3e65d49";
export const etherscanKey = "WM6JN7WNUTE4NF8PE8UYHVBHARWGZARPN8";

Moralis.start({
    apiKey: moralis_apikey,
});