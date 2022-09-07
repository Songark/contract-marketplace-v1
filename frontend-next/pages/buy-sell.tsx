import Head from 'next/head'
import React , { useState, useEffect} from 'react';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';
import BuySellSection from '../components/layouts/explore-02/BuySellSection'
import { useWeb3React } from "@web3-react/core";

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
        console.log(account);
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
