import Head from 'next/head'
import React from 'react';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';
import SliderStyle2 from '../components/slider/SliderStyle';
import Create from '../components/layouts/home/Create';


export default function Home() {
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
        <div className='home-5'>
            <Header />
            <SliderStyle2 />
            <Create />
            <Footer />
        </div>
    </>
  )
}