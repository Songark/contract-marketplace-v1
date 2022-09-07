import '../assets/css/shortcodes.css'
import '../assets/css/style.css'
import '../styles/globals.css'
// import '../src/App.css'
import 'swiper/scss'
import 'swiper/scss/navigation'
import 'swiper/scss/pagination'

import { Web3ReactProvider } from "@web3-react/core";
import { ethers } from "ethers";

const getLibrary = (provider) => {
  const library = new ethers.providers.Web3Provider(provider);
  library.pollingInterval = 8000; // frequency provider is polling
  return library;
};

function MyApp({ Component, pageProps }) {
  return (
    <Web3ReactProvider getLibrary={getLibrary}>
      <Component {...pageProps} />
    </Web3ReactProvider>
  )
}

export default MyApp
