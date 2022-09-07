import React from 'react';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';
import BuySellSection from '../components/layouts/explore-02/BuySellSection'
import todayPickData from '../assets/fake-data/data-today-pick';

const Buysell = () => {
    return (
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
            <BuySellSection data={todayPickData} />
            <Footer />
        </div>
    );
}

export default Buysell; 
