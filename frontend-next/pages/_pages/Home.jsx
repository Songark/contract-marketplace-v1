import React from 'react';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';
import SliderStyle2 from '../components/slider/SliderStyle2';
import heroSliderData from '../assets/fake-data/data-slider';
import Create from '../components/layouts/home-2/Create';

const Home = () => {
    return (
        <div className='home-5'>
            <Header />
            <SliderStyle2 data={heroSliderData} />
            <Create />
            <Footer />
        </div>
    );
}

export default Home;