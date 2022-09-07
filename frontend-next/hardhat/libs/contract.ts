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

async function getEventObject(transaction, eventName: string) {
    const receipt = await transaction.wait();
    const events = receipt.events.filter((v) => {return v.event === eventName;});
    for (let i = 0; i < events.length; i++) {
        console.log(events);
    }
}