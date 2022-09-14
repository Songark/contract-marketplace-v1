import Moralis  from 'moralis';
import { EvmChain } from '@moralisweb3/evm-utils';
import { contractType, contractAddress, chain, moralis_apikey } from './constants';

export async function getMyNFTs(type: contractType, address: string) {
    if (address !== undefined) {
        await Moralis.start({
            apiKey: moralis_apikey,
            // ...and any other configuration
        });

        const tokenAddress = contractAddress[type];
        
        const response = await Moralis.EvmApi.nft.getWalletNFTs
        ({
            address,
            chain,
            tokenAddresses: [tokenAddress]
        });
        return response.data.result;
    }
    return [];
}

export async function getTokenInfo(type: contractType, tokenId: string) {
    if (tokenId !== undefined) {
        await Moralis.start({
            apiKey: moralis_apikey,
            // ...and any other configuration
        });

        const address = contractAddress[type];
        
        const response = await Moralis.EvmApi.nft.getNFTMetadata({
            address,
            chain,
            tokenId,
        });
        return response.data;
    }
    return null;
}


        