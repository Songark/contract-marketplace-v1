import {ethers} from 'ethers';
import {
    nftEngine, 
    contractType,
    contractAddress,
    paymentType,
    infuraApiKey,
    chainName
} from "./constants";
import NFTEngineV1 from '../artifacts/contracts/engine/NFTEngineV1.sol/NFTEngineV1.json';
import MembershipNFTMock from '../artifacts/contracts/test/MembershipNFTMock.sol/MembershipNFTMock.json';
import CustomNFTMock from '../artifacts/contracts/test/CustomNFTMock.sol/CustomNFTMock.json';
import OwndTokenMock from '../artifacts/contracts/test/OwndTokenMock.sol/OwndTokenMock.json';

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
        const signer = provider.getSigner();
        const nftEngineV1WithSigner = nftEngineV1.connect(signer)
        await nftEngineV1WithSigner.createAuction(
            contractAddress[nftType],
            tokenId,
            payType == paymentType.pay_eth ? 
                ethers.constants.AddressZero : contractAddress[contractType.ownedToken],
            ethers.utils.parseEther(minPrice),
            ethers.utils.parseEther(buyNowPrice),
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
            await nftEngineV1.connect(provider.getSigner()).makeBid(
                contractAddress[nftType],
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
            const ownedContract = new ethers.Contract(
                contractAddress[contractType.ownedToken], 
                OwndTokenMock.abi, 
                provider);

            await ownedContract.connect(provider.getSigner()).approve(
                nftEngineV1.address,
                ethers.utils.parseEther(price)
            );
            await nftEngineV1.connect(provider.getSigner()).makeBid(
                contractAddress[nftType],
                tokenId,
                contractAddress[contractType.ownedToken],
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
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(
            contractAddress[nftType], 
            MembershipNFTMock.abi, 
            provider);
        await nftContract.connect(signer).approve(nftEngine, tokenId);

        const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, provider);        
        const nftEngineV1WithSigner = nftEngineV1.connect(signer)
        await nftEngineV1WithSigner.createSale(
            contractAddress[nftType],
            tokenId,
            payType == paymentType.pay_eth ? 
                ethers.constants.AddressZero : contractAddress[contractType.ownedToken],
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
            contractAddress[nftType],
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
    tokenInfos = await nftEngineV1.getTokenInfosOnSale(
        contractAddress[nftType],
        begin,
        size);
    return tokenInfos;
}

export async function getTokenIdsOnSale(
    nftType: contractType) 
{
    let tokenIds = [];
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    tokenIds = await nftEngineV1.getTokensIdsOnSale(contractAddress[nftType]);
    return tokenIds;
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
    tokenSaleInfo = await nftEngineV1.getTokenSaleInfo(contractAddress[nftType], tokenId);    
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
    tokenInfos = await nftEngineV1.getTokenInfosOnAuction(
        contractAddress[nftType],
        begin,
        size);
    return tokenInfos;
}

export async function getTokenIdsOnAuction(
    nftType: contractType) 
{
    let tokenIds = [];
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    tokenIds = await nftEngineV1.getTokenIdsOnAuction(contractAddress[nftType]);    
    return tokenIds
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
    tokenAuctionInfo = await nftEngineV1.getTokenAuctionInfo(contractAddress[nftType], tokenId);    
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
            contractAddress[nftType], tokenId
        );

        if (saleInfo.erc20Token == 0) 
        {
            await nftEngineV1.connect(provider.getSigner()).buyNFT(
                contractAddress[nftType],
                tokenId,
                {
                    value: saleInfo.price,
                    gasLimit: '1000000'
                }
            );
        }
        else {
            const ownedContract = new ethers.Contract(
                saleInfo.erc20Token, 
                OwndTokenMock.abi, 
                provider);

            await ownedContract.connect(provider.getSigner()).approve(
                nftEngineV1.address,
                saleInfo.price
            );
            await nftEngineV1.connect(provider.getSigner()).buyNFT(
                contractAddress[nftType],
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
    const _provider = await new ethers.providers.InfuraProvider(
        chainName, 
        infuraApiKey);
    const nftEngineV1 = new ethers.Contract(nftEngine, NFTEngineV1.abi, _provider);
    contractAddress = await nftEngineV1.getNFTContract(_type);
    console.log(contractAddress);
    return contractAddress;
}

