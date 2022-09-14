import React , { useState , Fragment } from 'react';
import  Link  from 'next/link'
import  Image  from 'next/image'
import { Tab, Tabs, TabList, TabPanel  } from 'react-tabs';
import 'react-tabs/style/react-tabs.css';
import CardModal from '../CardModal';


import img1 from '../../../assets/images/box-item/image-box-26.jpg'
import imga1 from '../../../assets/images/avatar/avt-1.jpg'
import imgCollection1 from '../../../assets/images/avatar/avt-18.jpg'
import img2 from '../../../assets/images/box-item/image-box-27.jpg'
import imga2 from '../../../assets/images/avatar/avt-2.jpg'
import imgCollection2 from '../../../assets/images/avatar/avt-18.jpg'
import img3 from '../../../assets/images/box-item/image-box-28.jpg'
import imga3 from '../../../assets/images/avatar/avt-4.jpg'
import imgCollection3 from '../../../assets/images/avatar/avt-18.jpg'
import img4 from '../../../assets/images/box-item/image-box-26.jpg'
import imga4 from '../../../assets/images/avatar/avt-3.jpg'
import imgCollection4 from '../../../assets/images/avatar/avt-18.jpg'
import img5 from '../../../assets/images/box-item/image-box-27.jpg'
import imga5 from '../../../assets/images/avatar/avt-12.jpg'
import imgCollection5 from '../../../assets/images/avatar/avt-18.jpg'
import img6 from '../../../assets/images/box-item/image-box-28.jpg'
import imga6 from '../../../assets/images/avatar/avt-1.jpg'
import imgCollection6 from '../../../assets/images/avatar/avt-18.jpg'
import img7 from '../../../assets/images/box-item/image-box-26.jpg'
import imga7 from '../../../assets/images/avatar/avt-4.jpg'
import imgCollection7 from '../../../assets/images/avatar/avt-18.jpg'
import img8 from '../../../assets/images/box-item/image-box-27.jpg'
import imga8 from '../../../assets/images/avatar/avt-3.jpg'
import imgCollection8 from '../../../assets/images/avatar/avt-18.jpg'

const PNFTSection = () => {
    const [dataTab] = useState(
        [
            {
                id: 4,
                title: "PNFT",
            }
        ]
    )
    const [dataPanel] = useState(
        [
            {
                id: 4,
                dataContent: [
                    {
                        id: 1,
                        img: img1,
                        title: "The RenaiXance Rising the sun ",
                        tags: "bsc",
                        imgAuthor: imga1,
                        nameAuthor: "SalvadorDali",
                        price: "4.89 ETH",
                        priceChange: "$12.246",
                        wishlist: "100",
                        imgCollection: imgCollection1,
                        nameCollection: "Creative Art 3D"
                    },
                    {
                        id: 2,
                        img: img2,
                        title: "The RenaiXance Rising the sun ",
                        tags: "bsc",
                        imgAuthor: imga2,
                        nameAuthor: "SalvadorDali",
                        price: "4.89 ETH",
                        priceChange: "$12.246",
                        wishlist: "100",
                        imgCollection: imgCollection2,
                        nameCollection: "Creative Art 3D"
                    },
                    {
                        id: 3,
                        img: img3,
                        title: "The RenaiXance Rising the sun ",
                        tags: "bsc",
                        imgAuthor: imga3,
                        nameAuthor: "SalvadorDali",
                        price: "4.89 ETH",
                        priceChange: "$12.246",
                        wishlist: "100",
                        imgCollection: imgCollection3,
                        nameCollection: "Creative Art 3D"
                    },
                    {
                        id: 5,
                        img: img5,
                        title: "The RenaiXance Rising the sun ",
                        tags: "bsc",
                        imgAuthor: imga5,
                        nameAuthor: "SalvadorDali",
                        price: "4.89 ETH",
                        priceChange: "$12.246",
                        wishlist: "100",
                        imgCollection: imgCollection5,
                        nameCollection: "Creative Art 3D"
                    },
                    {
                        id: 7,
                        img: img7,
                        title: "The RenaiXance Rising the sun ",
                        tags: "bsc",
                        imgAuthor: imga7,
                        nameAuthor: "SalvadorDali",
                        price: "4.89 ETH",
                        priceChange: "$12.246",
                        wishlist: "100",
                        imgCollection: imgCollection7,
                        nameCollection: "Creative Art 3D"
                    },
                ]
            },
        ]
    )

    const [visible , setVisible] = useState(8);
    const showMoreItems = () => {
        setVisible((prevValue) => prevValue + 4);
    }

    const [modalShow, setModalShow] = useState(false);

    return (
        <Fragment>
            <div className="tf-section sc-explore-2">
                <div className="themesflat-container">
                    <div className="row">
                        <div className="col-md-12">
                            <div className="seclect-box style3">
                                <div id="artworks" className="dropdown">
                                    <Link href="#" className="btn-selector nolink"><a>All Artworks</a></Link>
                                    <ul>
                                        <li><span>Abstraction</span></li>
                                        <li className="active"><span>Skecthify</span></li>
                                        <li><span>Patternlicious</span></li>
                                        <li><span>Virtuland</span></li>
                                        <li><span>Papercut</span></li>
                                    </ul>
                                </div>
                                <div id="sort-by" className="dropdown style-2">
                                    <Link href="#" className="btn-selector nolink"><a>Sort by</a></Link>
                                    <ul>
                                        <li><span>Top rate</span></li>
                                        <li className="active"><span>Mid rate</span></li>
                                        <li><span>Low rate</span></li>
                                    </ul>
                                </div>    
                            </div>
                            <div className="flat-tabs explore-tab">
                                <Tabs >
                                    {/* <TabList>
                                        {
                                            dataTab.map(data=> (
                                                <Tab key={data.id} >{data.title}</Tab>
                                            ))
                                        }
                                    </TabList> */}
                                    {
                                        dataPanel.map(data =>(
                                            <TabPanel key={data.id}>
                                                {
                                                    
                                                    data.dataContent.slice(0,visible).map (item=>(
                                                    <div key={item.id} className={`sc-card-product explode style2 mg-bt ${item.feature ? 'comingsoon' : '' } `}>                               
                                                        <div className="card-media">
                                                            <Link href="/item-details-01"><a><Image src={item.img} alt="Axies" /></a></Link>
                                                            <div className="button-place-bid">
                                                                <button onClick={() => setModalShow(true)} className="sc-button style-place-bid style bag fl-button pri-3"><span>Place Bid</span></button>
                                                            </div>
                                                            <Link href="/login" className="wishlist-button heart"><a><span className="number-like">{item.wishlist}</span></a></Link>
                                                            <div className="coming-soon">{item.feature}</div>
                                                        </div>
                                                        <div className="card-title">
                                                            <h5><Link href="/item-details-01"><a>{item.title}</a></Link></h5>
                                                            
                                                        </div>
                                                        <div className="meta-info">
                                                            <div className="author">
                                                                <div className="avatar">
                                                                    <Image src={item.imgAuthor} alt="Axies" />
                                                                </div>
                                                                <div className="info">
                                                                    <span>Creator</span>
                                                                    <h6> <Link href="/authors-02"><a>{item.nameAuthor}</a></Link> </h6>
                                                                </div>
                                                            </div>
                                                            <div className="tags">{item.tags}</div>
                                                        </div>
                                                        <div className="card-bottom style-explode">
                                                            <div className="price">
                                                                <span>Current Bid</span>
                                                                <div className="price-details">
                                                                    <h5>{item.price}</h5>
                                                                    <span>= {item.priceChange}</span>
                                                                </div>
                                                            </div>
                                                            <Link href="/activity-01" className="view-history reload"><a>View History</a></Link>
                                                        </div>
                                                    </div>
                                                    ))
                                                }
                                                {
                                                    visible < data.dataContent.length && 
                                                    <div className="col-md-12 wrap-inner load-more text-center"> 
                                                        <Link href="#"><a id="load-more" className="sc-button loadmore fl-button pri-3" onClick={showMoreItems}><span>Load More</span></a></Link>
                                                    </div>
                                                }
                                            </TabPanel>
                                        ))
                                    }
                                </Tabs>
                            </div> 
                        </div>   
                    </div>
                </div>
            </div>
            <CardModal
                show={modalShow}
                onHide={() => setModalShow(false)}
            />
        </Fragment>
    );
}

export default PNFTSection;