import Head from 'next/head'
import React , { useState, useEffect} from 'react';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';
import BuySellSection from '../components/layouts/explore-02/BuySellSection'
import { useWeb3React } from "@web3-react/core";
import { getMyNFTs, getTokenInfo } from '../hardhat/libs/nftmoralis';
import { 
    getTokenInfosOnSale,
    getTokenIdsOnSale, 
    getTokenSaleInfo,
    getTokenInfosOnAuction,
    getTokenIdsOnAuction,
    getTokenAuctionInfo 
} from '../hardhat/libs/contract';
import { contractType } from '../hardhat/libs/constants';

const Buysell = () => {
    const {
        library,
        chainId,
        account,
        activate,
        deactivate,
        active
    } = useWeb3React();

    useEffect(() => {
        const fetch_data = async () => {
            console.log(account);
            if (account !== undefined) {
                const nfts = await getMyNFTs(contractType.membershipNFT, account);
                console.log(nfts);                        
            }
            const tokenSales = await getTokenInfosOnSale(contractType.membershipNFT, 0, 10);
            console.log(tokenSales);  
            const tokenInfo = await getTokenInfo(contractType.membershipNFT, "1")
            console.log(tokenInfo);    
            const tokenIds = await getTokenIdsOnSale(contractType.membershipNFT);
            console.log(tokenIds);    
            for (let i = 0; i < tokenSales.length; i++) {
                const tokenSaleInfo = await getTokenSaleInfo(contractType.membershipNFT, tokenIds[i]);
                console.log(tokenSaleInfo);  
            }    
        }

        fetch_data();        
    }, []);

    return (
        <>
            <Head>
                <title>PlayEstates | NFT Marketplace</title>
                <meta name="description" content="PlayEstates NFT Marketplace" />
                <meta httpEquiv="Content-Type" content="text/html; charset=utf-8" />
                <meta name="author" content="playestates.com" />
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />

                <link rel="icon" href="/Favicon.png" />
                <link rel="apple-touch-icon-precomposed" href="%PUBLIC_URL%/assets/icon/Favicon.png"></link>
            </Head>
            <div className='explore'>
                <Header />
                <section className="flat-title-page inner">
                    <div className="overlay"></div>
                    <div className="themesflat-container">
                        <div className="row">
                            <div className="col-md-12">
                                <div className="page-title-heading mg-bt-12">
                                    <h1 className="heading text-center">Buy/Sell</h1>
                                </div>
                            </div>
                        </div>
                    </div>                    
                </section>
                <BuySellSection />
                <Footer />
            </div>
        </>
    );
}

export default Buysell; 
