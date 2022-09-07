import React from 'react';
import Link  from 'next/link';
import Header from '../components/header/Header';
import Footer from '../components/footer/Footer';

const SignUp = () => {
    return (
        <div>
            <Header />
            <section className="flat-title-page inner">
                <div className="overlay"></div>
                <div className="themesflat-container">
                    <div className="row">
                        <div className="col-md-12">
                            <div className="page-title-heading mg-bt-12">
                                <h1 className="heading text-center">Signup</h1>
                            </div>
                        </div>
                    </div>
                </div>                    
            </section>
            <section className="tf-login tf-section">
                <div className="themesflat-container">
                    <div className="row">
                        <div className="col-12">
                            <div className="flat-form box-login-social">
                                <div className="box-title-login">
                                    <h5>Login with social</h5>
                                </div>
                                <ul>
                                    <li>
                                        <Link href="#" className="sc-button style-2 fl-button pri-3">
                                            <a>
                                                <i className="icon-fl-google-2"></i>
                                                <span>Google</span>
                                            </a>
                                        </Link>
                                    </li>
                                    <li>
                                        <Link href="#" className="sc-button style-2 fl-button pri-3">
                                            <a>
                                                <i className="icon-fl-facebook"></i>
                                                <span>Facebook</span>
                                            </a>
                                        </Link>
                                    </li>
                                </ul>
                            </div>

                            <div className="flat-form box-login-email">
                                <div className="box-title-login">
                                    <h5>Or login with email</h5>
                                </div>

                                <div className="form-inner">
                                    <form action="#" id="contactform">
                                        <input id="name" name="name" tabIndex="1" aria-required="true" required type="text" placeholder="Your Full Name" />
                                        <input id="email" name="email" tabIndex="2"  aria-required="true" type="email" placeholder="Your Email Address" required />
                                        <input id="pass" name="pass" tabIndex="3"  aria-required="true" type="text" placeholder="Set Your Password" required />
                                        <div className="row-form style-1">
                                            <label>Remember me
                                                <input type="checkbox" />
                                                <span className="btn-checkbox"></span>
                                            </label>
                                            <Link href="#" className="forgot-pass"><a>Forgot Password ?</a></Link>
                                        </div>

                                        <button className="submit">Login</button>
                                    </form>
                                </div>

                            </div>

                        </div>
                    </div>
                </div>
            </section>
            <Footer />
        </div>
    );
}

export default SignUp;
