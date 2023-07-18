import {ethers} from 'ethers';
import {
    nftEngine, 
    contractType,
    nftAddress,
    payTokenAddress,
    paymentType,
    infuraApiKey,
    chainName
} from "./constants";
import NFTEngineV1 from '../artifacts/contracts/engine/NFTEngineV1.sol/NFTEngineV1.json';
import MembershipNFT from '../artifacts/contracts/token/MembershipNFT.sol/MembershipNFT.json';
import PBRTToken from '../artifacts/contracts/token/PlayEstatesBrickToken.sol/PlayEstatesBrickToken.json';
import USDCToken from './usdcABI.json';
import CustomNFTMock from '../artifacts/contracts/test/CustomNFTMock.sol/CustomNFTMock.json';
import Contracts from './contract.json';

const payTokenAbis: any[] = [null, PBRTToken.abi, USDCToken];

export async function createAuction(
    provider, 
    nftType: contractType, 
    tokenId: number, 
    payType: paymentType,
    minPrice: string,
    buyNowPrice: string,
    periodSeconds: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        const signer = provider.getSigner();
        const nftEngineV1WithSigner = nftEngineV1.connect(signer)
        await nftEngineV1WithSigner.createAuction(
            nftAddress[nftType],
            tokenId,
            payTokenAddress[payType],
            ethers.utils.parseEther(minPrice),
            ethers.utils.parseEther(buyNowPrice),
            periodSeconds,
            [], 
            [],
            {
                gasLimit: '1000000'
            }
        );
    }
}

export async function settleAuction(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.settleAuction(
            nftAddress[nftType],
            tokenId
        );
    }
}

export async function withdrawAuction(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.withdrawAuction(
            nftAddress[nftType],
            tokenId
        );
    }
}

export async function takeHighestBid(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.takeHighestBid(
            nftAddress[nftType],
            tokenId
        );
    }
}

export async function makeBid(
    provider, 
    nftType: contractType, 
    tokenId: number,
    payType: paymentType,
    price: string) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        if (payType == paymentType.pay_eth) {
            await nftEngineV1.connect(provider.getSigner()).makeBid(
                nftAddress[nftType],
                tokenId,
                ethers.constants.AddressZero,
                0,
                {
                    value: ethers.utils.parseEther(price),
                    gasLimit: '1000000'
                }
            );
        }
        else {
            const payTokenContract = new ethers.Contract(
                payTokenAddress[payType], 
                payTokenAbis[payType], 
                provider);

            await payTokenContract.connect(provider.getSigner()).approve(
                nftEngineV1.address,
                ethers.utils.parseEther(price)
            );
            await nftEngineV1.connect(provider.getSigner()).makeBid(
                nftAddress[nftType],
                tokenId,
                payTokenAddress[payType],
                ethers.utils.parseEther(price),
                {
                    gasLimit: '1000000'
                }
            );
        }
    }
}

export async function withdrawBid(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.withdrawBid(
            nftAddress[nftType],
            tokenId
        );
    }
}

export async function createSale(
    provider, 
    nftType: contractType, 
    tokenId: number, 
    payType: paymentType,
    sellPrice: string) 
{
    if (provider !== undefined) {
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(
            nftAddress[nftType], 
            MembershipNFT.abi, 
            provider);
        await nftContract.connect(signer).approve(nftEngine, tokenId);

        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);        
        const nftEngineV1WithSigner = nftEngineV1.connect(signer)
        await nftEngineV1WithSigner.createSale(
            nftAddress[nftType],
            tokenId,
            payTokenAddress[payType],
            ethers.utils.parseEther(sellPrice),
            [], 
            [],
            {
                gasLimit: '1000000'
            }
        );
    }
}

export async function withdrawSale(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.withdrawSale(
            nftAddress[nftType],
            tokenId
        );
    }
}

export async function getTokenInfosOnSale(
    nftType: contractType,
    begin: number,
    size: number) 
{
    let tokenInfos = [];
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    const allTokenInfos = await nftEngineV1.getTokenInfosOnSale(nftAddress[nftType]);
    if (allTokenInfos.length > begin) {
        if (allTokenInfos.length >= begin + size) {
            tokenInfos = allTokenInfos.slice(begin, begin + size);
        }
        else {
            tokenInfos = allTokenInfos.slice(begin);
        }
    }
    return tokenInfos;
}

export async function getTokenSaleInfo(
    nftType: contractType,
    tokenId: number) 
{
    let tokenSaleInfo;
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    tokenSaleInfo = await nftEngineV1.getTokenSaleInfo(nftAddress[nftType], tokenId);    
    return tokenSaleInfo;
}

export async function getTokenInfosOnAuction(
    nftType: contractType,
    begin: number,
    size: number) 
{
    let tokenInfos = [];
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    const allTokenInfos = await nftEngineV1.getTokenInfosOnAuction(nftAddress[nftType]);
    if (allTokenInfos.length > begin) {
        if (allTokenInfos.length >= begin + size) {
            tokenInfos = allTokenInfos.slice(begin, begin + size);
        }
        else {
            tokenInfos = allTokenInfos.slice(begin);
        }
    }
    return tokenInfos;
}

export async function getTokenAuctionInfo(
    nftType: contractType,
    tokenId: number) 
{
    let tokenAuctionInfo;
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    tokenAuctionInfo = await nftEngineV1.getTokenAuctionInfo(nftAddress[nftType], tokenId);    
    return tokenAuctionInfo;
}

export async function buyNFT(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        const saleInfo = await nftEngineV1.getTokenSaleInfo(
            nftAddress[nftType], tokenId
        );

        if (saleInfo.erc20Token == 0) 
        {
            await nftEngineV1.connect(provider.getSigner()).buyNFT(
                nftAddress[nftType],
                tokenId,
                {
                    value: saleInfo.price,
                    gasLimit: '1000000'
                }
            );
        }
        else {
            const payTokenContract = new ethers.Contract(
                saleInfo.erc20Token, 
                PBRTToken.abi, 
                provider);

            await payTokenContract.connect(provider.getSigner()).approve(
                nftEngineV1.address,
                saleInfo.price
            );

            await nftEngineV1.connect(provider.getSigner()).buyNFT(
                nftAddress[nftType],
                tokenId,
                {
                    gasLimit: '1000000'
                }
            );
        } 
    }
}

export async function getEventObject(transaction, eventName: string) {
    const receipt = await transaction.wait();
    const events = receipt.events.filter((v) => {return v.event === eventName;});
    let eventObj;
    if (events.length > 0)
        eventObj = events[0].args;
    return eventObj;
}

export async function getContractAddress(_type: contractType) {
    let contractAddress: any;
    if (_type == contractType.pbrtToken) {
        contractAddress = payTokenAddress[1];
    }
    else if (_type == contractType.usdtToken) {
        contractAddress = payTokenAddress[2];
    }
    else {
        const _provider = await new ethers.providers.InfuraProvider(
            chainName, 
            infuraApiKey);
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
        contractAddress = await nftEngineV1.getNFTContract(_type);    
    }
    
    console.log(contractAddress);
    return contractAddress;
}

