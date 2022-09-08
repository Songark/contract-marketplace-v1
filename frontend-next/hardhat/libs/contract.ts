import {ethers} from 'ethers';
import {
    nftEngine, 
    contractType,
    contractAddress,
    paymentType
} from "./constants";
import NFTEngineV1 from '../artifacts/contracts/engine/NFTEngineV1.sol/NFTEngineV1.json';

export async function createAuction(
    provider, 
    nftType: contractType, 
    tokenId: number, 
    payType: paymentType,
    minPrice: string,
    buyNowPrice: string) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.createAuction(
            contractAddress[nftType],
            tokenId,
            payType == paymentType.pay_eth ? 
                ethers.constants.AddressZero : contractAddress[contractType.ownedToken],
            ethers.utils.parseEther(minPrice),
            ethers.utils.parseEther(buyNowPrice),
            [], 
            []
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
            contractAddress[nftType],
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
            contractAddress[nftType],
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
            contractAddress[nftType],
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
            await nftEngineV1.makeBid(
                contractAddress[nftType],
                tokenId,
                ethers.constants.AddressZero,
                0,
                {value: ethers.utils.parseEther(price)}
            );
        }
        else {
            await nftEngineV1.makeBid(
                contractAddress[nftType],
                tokenId,
                contractAddress[contractType.ownedToken],
                ethers.utils.parseEther(price)
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
            contractAddress[nftType],
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
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.createSale(
            contractAddress[nftType],
            tokenId,
            payType == paymentType.pay_eth ? 
                ethers.constants.AddressZero : contractAddress[contractType.ownedToken],
            ethers.utils.parseEther(sellPrice),
            [], 
            []
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
            contractAddress[nftType],
            tokenId
        );
    }
}

export async function getTokensOnSale(
    provider, 
    nftType: contractType) 
{
    let tokenSales = [];
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenSales = await nftEngineV1.getTokensOnSale(contractAddress[nftType]);
    }
    return tokenSales;
}

export async function getTokenSaleInfo(
    provider, 
    nftType: contractType,
    tokenId: number) 
{
    let tokenSaleInfo;
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenSaleInfo = await nftEngineV1.getTokenSaleInfo(contractAddress[nftType], tokenId);
    }
    return tokenSaleInfo;
}

export async function getTokensOnAuction(
    provider, 
    nftType: contractType) 
{
    let tokenAuctions = [];
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenAuctions = await nftEngineV1.getTokensOnAuction(contractAddress[nftType]);
    }
    return tokenAuctions
}

export async function getTokenAuctionInfo(
    provider, 
    nftType: contractType,
    tokenId: number) 
{
    let tokenAuctionInfo;
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        tokenAuctionInfo = await nftEngineV1.getTokenAuctionInfo(contractAddress[nftType], tokenId);
    }
    return tokenAuctionInfo;
}

export async function buyNFT(
    provider, 
    nftType: contractType, 
    tokenId: number) 
{
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        await nftEngineV1.buyNFT(
            contractAddress[nftType],
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

async function getContractAddress(provider, _type: contractType) {
    let contractAddress: any;
    if (provider !== undefined) {
        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);
        contractAddress = await nftEngineV1.getNFTContract(
            _type
        );
    }
    console.log(contractAddress);
    return contractAddress;
}