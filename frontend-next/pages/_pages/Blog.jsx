import React, {useState} from 'react';
import  Link  from 'next/link';
import blogData from  '../assets/fake-data/data-blog'
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';

const Blog = () => {
    const [data] = useState(blogData);

    const [visible , setVisible] = useState(6);
    const showMoreItems = () => {
        setVisible((prevValue) => prevValue + 3);
    }
    return (
        <div>
            <Header />
            <section className="flat-title-page inner">
                <div className="overlay"></div>
                <div className="themesflat-container">
                    <div className="row">
                        <div className="col-md-12">
                            <div className="page-title-heading mg-bt-12">
                                <h1 className="heading text-center">Blog</h1>
                            </div>
                            <div className="breadcrumbs style2">
                                <ul>
                                    <li><Link href="/">Home</Link></li>
                                    <li><Link href="#">Resources</Link></li>
                                    <li>Blog</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>                    
            </section>
            <div className="tf-section sc-card-blog dark-style2">
                <div className="themesflat-container">
                    <div className="row">
                        {
                            data.slice(0,visible).map((item,index) => (
                                <BlogItem key={index} item={item} />
                            ))
                        }
                        {
                            visible < data.length && 
                            <div className="col-md-12 wrap-inner load-more text-center"> 
                                <Link href="#" id="load-more" className="sc-button loadmore fl-button pri-3 mt-6" onClick={showMoreItems}><span>Load More</span></Link>
                            </div>
                        }
                    </div>
                </div>
            </div>
            <Footer />
        </div>
    );
}

const BlogItem = props => (
    <div className="fl-blog fl-item2 col-lg-4 col-md-6">
        <article className="sc-card-article">
            <div className="card-media">
                <Link href="/blog-details"><img src={props.item.img} alt="Axies" /></Link>
            </div>
            <div className="meta-info">
                <div className="author">
                    <div className="avatar">
                        <img src={props.item.imgAuthor} alt="Axies" />
                    </div>
                    <div className="info">
                        <span>Post owner</span>
                        <h6> <Link href="/author-02">{props.item.nameAuthor}</Link> </h6>
                    </div>
                </div>
                <div className="date">{props.item.time}</div>
            </div>
            <div className="text-article">
                <h3><Link href="/blog-details">{props.item.title}</Link></h3>
                <p>{props.item.content}</p>
            </div>
            <Link href="/blog-details" className="sc-button fl-button pri-3"><span>Read More</span></Link>
        </article>
    </div>
)

export default Blog;
