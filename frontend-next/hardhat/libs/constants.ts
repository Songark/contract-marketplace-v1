import { EvmChain } from '@moralisweb3/evm-utils';

export const chain = EvmChain.RINKEBY;
export const moralis_apikey = "LZ0l9LCHbzG9IaN9ltkswy1voYRgcUBWDWZ5Ar5tFaAVKT5ctwHqlCUJ9y7tNZHd";
export const nftEngine = "0xCC57ddD4B4D666F8587E8dD21Ecb7C4b99c5b8C1"; 

export enum contractType {
    customNFT,
    fractionalNFT,
    membershipNFT,
    ownedToken
};

export const contractAddress: string[] = [
    "0xcc2a784D79288D7c618e2699Bc7e180Dc99dFf94",   // customNFT
    "0xC905Ec8c805aB8277624CccF4065631647A88fd0",   // fractionalNFT
    "0x535ae52DaFc308bF3Dd82031701b4d5851Cc01b4",   // membershipNFT
    "0x5376B0d06214E96bc45d1f098B87652dd43F4EA7"    // owned token
]

export enum paymentType {
    pay_eth,
    pay_erc20
}

export const infuraToken = "5c948ab130cc463a9f712ecde3e65d49";
export const etherscanKey = "WM6JN7WNUTE4NF8PE8UYHVBHARWGZARPN8";
