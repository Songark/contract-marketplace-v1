import React, {useEffect} from 'react';
import Link from 'next/link'
import Image from 'next/image'
import imgsun from '../../assets/images/icon/sun.png'

const DarkMode = () => {

    let clickedClass = "clicked"

    const switchTheme = e => {
        let body;
        body = document.body

        const lightTheme = "light"
        const darkTheme = "is_dark"
        let theme

        if (localStorage) {
            theme = localStorage.getItem("theme")
        }
        if (theme === lightTheme || theme === darkTheme) {
            body.classList.add(theme)
        } else {
            body.classList.add(darkTheme)
        }

        if (theme === darkTheme) {
            body.classList.replace(darkTheme, lightTheme)
            e.target.classList.remove(clickedClass)
            localStorage.setItem("theme", "light")
            theme = lightTheme
        } else {
            body.classList.replace(lightTheme, darkTheme)
            e.target.classList.add(clickedClass)
            localStorage.setItem("theme", "is_dark")
            theme = darkTheme
        }
    }
    return (
        <div className="mode_switcher">
            <Link href="#">
                <a onClick={e => switchTheme(e)}>
                    <Image src={imgsun} alt="" />
                </a>
            </Link>
        </div>
    );

}

export default DarkMode;