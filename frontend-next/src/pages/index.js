import Home from "./Home";
import Buysell from "./Buysell";
import BuyPNFTs from "./BuyPNFTs";
import LiveAuctions from "./LiveAuctions";
import ItemDetails01 from "./ItemDetails01";
import Activity01 from "./Activity01";
import Blog from "./Blog";
import BlogDetails from "./BlogDetails";
import HelpCenter from "./HelpCenter";
import Authors01 from "./Authors01";
import Authors02 from "./Authors02";
import WalletConnect from "./WalletConnect";
import CreateItem from "./CreateItem";
import EditProfile from "./EditProfile";
import Ranking from "./Ranking";
import Login from "./Login";
import SignUp from "./SignUp";
import NoResult from "./NoResult";
import FAQ from "./FAQ";
import Contact02 from "./Contact02";

const routes = [
  { path: '/', component: <Home />},
  { path: '/buy-sell', component: <Buysell />},
  { path: '/buy-pnfts', component: <BuyPNFTs />},
  { path: '/live-auctions', component: <LiveAuctions />},
  { path: '/item-details-01', component: <ItemDetails01 />},
  { path: '/activity-01', component: <Activity01 />},
  { path: '/blog', component: <Blog />},
  { path: '/blog-details', component: <BlogDetails />},
  { path: '/help-center', component: <HelpCenter />},
  { path: '/authors-01', component: <Authors01 />},
  { path: '/authors-02', component: <Authors02 />},
  { path: '/wallet-connect', component: <WalletConnect />},
  { path: '/create-item', component: <CreateItem />},
  { path: '/edit-profile', component: <EditProfile />},
  { path: '/ranking', component: <Ranking />},
  { path: '/login', component: <Login />},
  { path: '/sign-up', component: <SignUp />},
  { path: '/no-result', component: <NoResult />},
  { path: '/faq', component: <FAQ />},
  { path: '/contact-02', component: <Contact02 />},
]

export default routes;