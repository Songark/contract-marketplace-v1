import { EvmChain } from '@moralisweb3/evm-utils';
import Moralis  from 'moralis';

export const chain = EvmChain.GOERLI;
export const chainName = "goerli";

export const moralis_apikey = "7ppyBj1nGG2aydKjrga4UyBTSoj6enVAU0n25zcYLbnYFA4oA4Cn7h6fuYgKg3xw";
export const nftEngine = "0x878b6eE9784A6a08BAdc18c140C19C36bdb6e4A7";

export enum contractType {
    customNFT,
    membershipNFT,
    brickToken
};

export const contractAddress: string[] = [
    "0xCBDC5Eb81AF6c156c49341C2B12b998849992463",   // customNFT
    "0xc08BA1198fA68aA12BBa73C1c5b3FCB6243cbe6a",   // membershipNFT
    "0xb1677C5639CC483267cC720833d09e0ABd10000A"    // pbrt token
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