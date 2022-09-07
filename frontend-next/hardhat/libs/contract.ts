import {ethers} from 'ethers';
import {
    nftEngine, 
    nftContractType,
    nftContracts,
    paymentType,
    owndToken
} from "./constants";
import NFTEngineV1 from '../artifacts/contracts/engine/NFTEngineV1.sol/NFTEngineV1.json';

export async function createAuction(
    provider, 
    nftType: nftContractType, 
    tokenId: number, 
    payType: paymentType,
    minPrice: string,
    buyNowPrice: string) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.createAuction(
            nftContracts[nftType],
            tokenId,
            payType == paymentType.pay_eth ? ethers.constants.AddressZero : owndToken,
            ethers.utils.parseEther(minPrice),
            ethers.utils.parseEther(buyNowPrice),
            [], 
            []
        );
    }
}

export async function settleAuction(
    provider, 
    nftType: nftContractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.settleAuction(
            nftContracts[nftType],
            tokenId
        );
    }
}

export async function withdrawAuction(
    provider, 
    nftType: nftContractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.withdrawAuction(
            nftContracts[nftType],
            tokenId
        );
    }
}

export async function takeHighestBid(
    provider, 
    nftType: nftContractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.takeHighestBid(
            nftContracts[nftType],
            tokenId
        );
    }
}

export async function makeBid(
    provider, 
    nftType: nftContractType, 
    tokenId: number,
    payType: paymentType,
    price: string) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        if (payType == paymentType.pay_eth) {
            await nftEngineV1.makeBid(
                nftContracts[nftType],
                tokenId,
                ethers.constants.AddressZero,
                0,
                {value: ethers.utils.parseEther(price)}
            );
        }
        else {
            await nftEngineV1.makeBid(
                nftContracts[nftType],
                tokenId,
                owndToken,
                ethers.utils.parseEther(price)
            );
        }
    }
}

export async function withdrawBid(
    provider, 
    nftType: nftContractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.withdrawBid(
            nftContracts[nftType],
            tokenId
        );
    }
}

export async function createSale(
    provider, 
    nftType: nftContractType, 
    tokenId: number, 
    payType: paymentType,
    sellPrice: string) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.createSale(
            nftContracts[nftType],
            tokenId,
            payType == paymentType.pay_eth ? ethers.constants.AddressZero : owndToken,
            ethers.utils.parseEther(sellPrice),
            [], 
            []
        );
    }
}

export async function withdrawSale(
    provider, 
    nftType: nftContractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.withdrawSale(
            nftContracts[nftType],
            tokenId
        );
    }
}

export async function getTokensOnSale(
    provider, 
    nftType: nftContractType) 
{
    let tokenSales = [];
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenSales = await nftEngineV1.getTokensOnSale(nftContracts[nftType]);
    }
    return tokenSales;
}

export async function getTokenSaleInfo(
    provider, 
    nftType: nftContractType,
    tokenId: number) 
{
    let tokenSaleInfo;
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenSaleInfo = await nftEngineV1.getTokenSaleInfo(nftContracts[nftType], tokenId);
    }
    return tokenSaleInfo;
}

export async function getTokensOnAuction(
    provider, 
    nftType: nftContractType) 
{
    let tokenAuctions = [];
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenAuctions = await nftEngineV1.getTokensOnAuction(nftContracts[nftType]);
    }
    return tokenAuctions
}

export async function getTokenAuctionInfo(
    provider, 
    nftType: nftContractType,
    tokenId: number) 
{
    let tokenAuctionInfo;
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenAuctionInfo = await nftEngineV1.getTokenAuctionInfo(nftContracts[nftType], tokenId);
    }
    return tokenAuctionInfo;
}

export async function buyNFT(
    provider, 
    nftType: nftContractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.buyNFT(
            nftContracts[nftType],
            tokenId
        );
    }
}

async function getEventObject(transaction, eventName: string) {
    const receipt = await transaction.wait();
    const events = receipt.events.filter((v) => {return v.event === eventName;});
    let eventObj;
    if (events.length > 0)
        eventObj = events[0].args;
    return eventObj;
}