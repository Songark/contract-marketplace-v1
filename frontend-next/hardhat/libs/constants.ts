import { EvmChain } from '@moralisweb3/evm-utils';
import Moralis  from 'moralis';

export const chain = EvmChain.GOERLI;
export const chainName = "goerli";

export const moralis_apikey = "7ppyBj1nGG2aydKjrga4UyBTSoj6enVAU0n25zcYLbnYFA4oA4Cn7h6fuYgKg3xw";
export const nftEngine = "0x0a3159eC4A5a15690fE6A00551bb6f5dB07c3968";

export enum contractType {
    customNFT,
    fractionalNFT,
    membershipNFT,
    ownedToken
};

export const contractAddress: string[] = [
    "0x4e3eDbA355A82433f4eCc812B0A30d2c1266c1fF",   // customNFT
    "0xE55A593606C3c0b17bfC255D273dfAF3900F01b7",   // fractionalNFT
    "0xbB70C9d0c25EdFAf6Bf03B738756140771d4096E",   // membershipNFT
    "0x34D76Adbf0951A3fBF3625af68622771850cE36d"    // owned token
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