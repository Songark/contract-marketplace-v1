import React from 'react';
import  Link  from 'next/link'
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';
import PNFTSection from '../components/layouts/explore-02/PNFTSection'
import PNFTData from '../assets/fake-data/data-pnft';

const BuyPNFTs = () => {
    return (
        <div className='explore'>
            <Header />
            <section className="flat-title-page inner">
                <div className="overlay"></div>
                <div className="themesflat-container">
                    <div className="row">
                        <div className="col-md-12">
                            <div className="page-title-heading mg-bt-12">
                                <h1 className="heading text-center">Buy PNFTs</h1>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            <PNFTSection data={PNFTData} />
            <Footer />
        </div>
    );
}

export default BuyPNFTs; 
