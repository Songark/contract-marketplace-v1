import React , { useState, useEffect} from 'react';
import Head from 'next/head'
import Link  from 'next/link';
import Image  from 'next/image';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';

import Lists from '../components/layouts/NetworkLists';

import { useWeb3React } from "@web3-react/core";
import { networkParams } from '../components/blockchain/networks';
import { connectors } from '../components/blockchain/connectors';
import { toHex, truncateAddress } from "../components/blockchain/utils";
import NetworkLists from '../components/layouts/NetworkLists';

import { getTokensOnSale } from '../hardhat/libs/contract';
import { nftContractType } from '../hardhat/libs/constants';

const WalletConnect = () => {
    const {
        library,
        chainId,
        account,
        activate,
        deactivate,
        active
    } = useWeb3React();

    const [signature, setSignature] = useState("");
    const [error, setError] = useState("");
    const [network, setNetwork] = useState(undefined);
    const [message, setMessage] = useState("");
    const [signedMessage, setSignedMessage] = useState("");
    const [verified, setVerified] = useState();

    const handleNetwork = (e) => {
        const id = e.target.value;
        setNetwork(Number(id));
    };

    const refreshState = () => {
        window.localStorage.setItem("provider", undefined);
        setNetwork("");
        setMessage("");
        setSignature("");
        setVerified(undefined);
    }

    const disconnect = () => {
        refreshState();
        deactivate();
    };

    const setProvider = (type) => {
        window.localStorage.setItem("provider", type);
    };

    useEffect(() => {
        const provider = window.localStorage.getItem("provider");
        if (provider) activate(connectors[provider]);      
    }, []);

    const itemClick = async (conn) => {
        activate(connectors[conn]);        
        setProvider(conn);
        await getTokensOnSale(library, nftContractType.membershipNFT);
    }
    
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
            <div>
                <Header />
                <section className="flat-title-page inner">
                    <div className="overlay"></div>
                    <div className="themesflat-container">
                        <div className="row">
                            <div className='col-md-12 mb-5'>
                                <div className="page-title-heading mg-bt-12">
                                    <h1 className="heading text-center">Connect your wallet</h1>
                                </div>
                            </div>
                        </div>

                        <div className='row'>
                            <div className="offset-2 col-4 card my-auto" style={{color: 'black'}}>
                                <div className='text-center'>
                                    <h4 className="m-5">{`Connection Status : ${active}`}</h4>
                                    <h4 className="m-5">{`Account : ${truncateAddress(account)}`}</h4>
                                    <h4 className="m-5">{`Network ID : ${chainId ? chainId : "No Network"}`}</h4>
                                    <button className='py-3 mb-4' onClick={disconnect}>Disconnect</button>
                                </div>
                            </div>

                            <div className="col-4">
                                <NetworkLists itemClick={itemClick}/>
                            </div>
                        </div>
                    </div>                    
                </section>
                <div className="tf-connect-wallet tf-section">
                    <div className="themesflat-container">
                        <div className="row">
                            <div className="col-12">
                                <h5 className="sub-title ct style-1 pad-400">
                                    
                                </h5>
                            </div>
                            <div className="col-md-12">
                                <div className="sc-box-icon-inner style-2">
                                    {/* {
                                        data.map((item,index) => (
                                            <div key={index} className="sc-box-icon">
                                                <div className="img">
                                                    <Image src={item.img} />
                                                </div>
                                                <h4 className="heading"><Link href="/login">{item.title}</Link> </h4>
                                                <p className="content">{item.description}</p>
                                            </div>
                                        ))
                                    } */}
                                </div>  
                            </div>    
                        </div>              
                    </div>
                </div>
                <Footer />
            </div>
        </>
    );
}

export default WalletConnect;