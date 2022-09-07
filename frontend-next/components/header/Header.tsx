import React , { useRef , useState , useEffect } from 'react';
import Link from 'next/link'
import Image from 'next/image'
import { useRouter } from "next/router";
import {menus, userMenu} from "../../pages/menu";
import DarkMode from './DarkMode';
import logoheader from '../../assets/images/logo/logo.png'
import logoheader2x from '../../assets/images/logo/logo@2x.png'
import logodark from '../../assets/images/logo/logo_dark.png'
import logodark2x from '../../assets/images/logo/logo_dark@2x.png'
import imgsun from '../../assets/images/icon/sun.png'
import avt from '../../assets/images/avatar/avt-2.jpg'

import Dropdown from 'react-bootstrap/Dropdown';

export default function Header () {     

    const { pathname } = useRouter();

    const headerRef = useRef (null)
    useEffect(() => {
        window.addEventListener('scroll', isSticky);
        return () => {
            window.removeEventListener('scroll', isSticky);
        };
    });
    const isSticky = (e) => {
        const header = document.querySelector('.js-header');
        const scrollTop = window.scrollY;
        scrollTop >= 300 ? header.classList.add('is-fixed') : header.classList.remove('is-fixed');
        scrollTop >= 400 ? header.classList.add('is-small') : header.classList.remove('is-small');
    };

    const menuLeft = useRef(null)
    const btnToggle = useRef(null)
    const btnSearch = useRef(null)

    const menuToggle = () => {
        menuLeft.current.classList.toggle('active');
        btnToggle.current.classList.toggle('active');
    }

    const searchBtn = () => {
        btnSearch.current.classList.toggle('active');
    }

    const [activeIndex, setActiveIndex] = useState(null);
    const handleOnClick = index => {
        setActiveIndex(index); 
    };

    const userItems = [
        {
            id: 5,
            sub: 'Profile',
            links: '/edit-profile'
        },
        {
            id: 7,
            sub: 'Login',
            links: '/login'
        },
        {
            id: 8,
            sub: 'Sign Up',
            links: '/sign-up'
        },
    ]

    return (
        <header id="header_main" className="header_1 js-header" ref={headerRef}>
            <div className="themesflat-container">
                <div className="row">
                    <div className="col-md-12">
                        <div id="site-header-inner"> 
                            <div className="wrap-box flex">
                                <div id="site-logo" className="clearfix">
                                    <div id="site-logo-inner">
                                        <Link href="/">
                                            <a className="main-logo">
                                                {/* <Image className='logo-light'  id="logo_header" src={logodark} srcSet={`${logodark2x}`} alt="nft-gaming" />
                                                <Image className='logo-dark'  id="logo_header" src={logoheader} srcSet={`${logoheader2x}`} alt="nft-gaming" /> */}
                                                {/* <Image className='logo-light'  id="logo_header" src={logodark} alt="nft-gaming" />
                                                <Image className='logo-dark'  id="logo_header" src={logoheader} alt="nft-gaming" /> */}
                                                <Image id="logo_header" src={logodark} alt="nft-gaming" />
                                            </a>
                                        </Link>
                                    </div>
                                </div>

                                <div className="mobile-button" ref={btnToggle} onClick={menuToggle}><span></span></div>

                                <nav id="main-nav" className="main-nav" ref={menuLeft} >
                                    <ul id="menu-primary-menu" className="menu">  
                                        <li className="menu-item">
                                            <a target="_blank" href="https://www.playestates.com">Homepage</a>
                                        </li>
                                        {
                                            menus.map((data, index) => (
                                                <li key={index} onClick={()=> handleOnClick(index)} className={`menu-item ${data.namesub ? 'menu-item-has-children' : '' } ${activeIndex === index ? 'active' : ''} ` }   >
                                                    <Link href={data.links}><a>{data.name}</a></Link>
                                                    {
                                                        // data.namesub &&
                                                        // <ul className="sub-menu" >
                                                        //     {
                                                        //         data.namesub.map((submenu) => (
                                                        //             <li key={submenu.id} className={`menu-item 
                                                        //                 ${
                                                        //                     pathname.asPath === submenu.links
                                                        //                     ? "current-item"
                                                        //                     : ""
                                                        //                 }
                                                        //             `}><Link href={submenu.links}><a>{submenu.sub}</a></Link></li>
                                                        //         ))
                                                        //     }
                                                        // </ul>
                                                    }
                                                    
                                                </li>
                                            ))
                                        }
                                    </ul>
                                </nav>
                                    
                                {/* <nav id="main-nav-user" className="main-nav main-nav-user">
                                    <ul id="menu-primary-menu" className="menu">  
                                        <li className="menu-item menu-item-has-children ">
                                            <Link href="#">
                                                <a className="rounded-border" target="_blank" href="https://www.playestates.com">
                                                    <i className="fa fa-user"></i>
                                                </a>
                                            </Link>
                                            <ul className='sub-menu'>
                                                {
                                                    userMenu.map((item, index) => (
                                                        <li className="menu-item">
                                                            <Link href={item.links} >
                                                                <a>{item.sub}</a>
                                                            </Link>
                                                        </li>
                                                    ))
                                                }                                                    
                                            </ul>
                                        </li>
                                    </ul>
                                </nav> */}

                                <div className="flat-search-btn flex">                                
                                    <div className="sc-btn-top mg-r-12 main-nav main-nav-user">
                                        <Link href="#">
                                            <a className="sc-button header-slider style style-1 fl-button pri-1">
                                                <i className='fa fa-user'></i>
                                            </a>
                                        </Link>
                                        <ul className='sub-menu'>
                                            {
                                                userMenu.map((item, index) => (
                                                    <li key={index} className="menu-item">
                                                        <Link href={item.links} >
                                                            <a>
                                                                <span>{item.sub}</span>
                                                            </a>
                                                        </Link>
                                                    </li>
                                                ))
                                            }                                                    
                                        </ul>
                                    </div>

                                    <div className="sc-btn-top mg-r-12" id="site-header">
                                        <Link href="/wallet-connect">
                                            <a className="sc-button header-slider style style-1 wallet fl-button pri-1">
                                                <span>Wallet connect</span>
                                            </a>
                                        </Link>
                                    </div>
                                    
                                    <div className="admin_active" id="header_admin">
                                        <div className="header_avatar">
                                            <div className="price">
                                                <span>2.45 <strong>ETH</strong> </span>
                                            </div>
                                            <Image
                                                className="avatar"
                                                src={avt}
                                                alt="avatar"
                                                />
                                            <div className="avatar_popup mt-20">
                                                <div className="d-flex align-items-center copy-text justify-content-between">
                                                    <span> 13b9ebda035r178... </span>
                                                    <Link href="/">
                                                        <a className="ml-2">
                                                            <i className="fal fa-copy"></i>
                                                        </a>
                                                    </Link>
                                                </div>
                                                <div className="d-flex align-items-center mt-10">
                                                    <Image
                                                        className="coin"
                                                        src={imgsun}
                                                        alt="/"
                                                        />
                                                    <div className="info ml-10">
                                                        <p className="text-sm font-book text-gray-400">Balance</p>
                                                        <p className="w-full text-sm font-bold text-green-500">16.58 ETH</p>
                                                    </div>
                                                </div>
                                                <div className="hr"></div>
                                                <div className="links mt-20">
                                                    <Link href="#">
                                                        <a>
                                                            <i className="fab fa-accusoft"></i> <span> My items</span>
                                                        </a>
                                                    </Link>
                                                    <a className="mt-10" href="/edit-profile">
                                                        <i className="fas fa-pencil-alt"></i> <span> Edit Profile</span>
                                                    </a>
                                                    <a className="mt-10" href="/login" id="logout">
                                                        <i className="fal fa-sign-out"></i> <span> Logout</span>
                                                    </a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div> 
                        </div>
                    </div>
                </div>
            </div>
            <DarkMode />
        </header>
    );
}

