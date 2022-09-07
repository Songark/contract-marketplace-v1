
import React , { useState, useEffect} from 'react';

import { ListGroup, Button, Image } from 'react-bootstrap';

// import Image from 'next/image';

import { Container, Row }  from 'react-bootstrap';

import { useWeb3React } from "@web3-react/core";
import { networkParams } from './networks';
import { connectors } from './connectors';
import { toHex, truncateAddress } from "./utils";

import img1 from '../../assets/images/icon/connect-1.png'
import img2 from '../../assets/images/icon/connect-2.png'
import img3 from '../../assets/images/icon/connect-3.png'
import img4 from '../../assets/images/icon/connect-4.png'
import img5 from '../../assets/images/icon/connect-5.png'
import img6 from '../../assets/images/icon/connect-6.png'
import img7 from '../../assets/images/icon/connect-7.png'
import img8 from '../../assets/images/icon/connect-8.png'

const Lists = () => {

  const data = [          
    {
        img: img1,
        conn: "injected",
        title: 'Meta Mask',
        description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt'
    },
    {
      img: img4,
      conn: "walletConnect",
      title: 'Wallet Connect',
      description: 'Metus corrupti itaque reiciendis, provident condimentum, reprehenderit numquam, mi'
    },
    {
        img: img5,
        conn: "coinbaseWallet",
        title: 'Coinbase Wallet',
        description: 'Sollicitudin iure conubia vivamus habitasse aptent, eligendi deserunt excepteur tellus non'
    },
    {
        img: img2,
        title: 'Bitski',
        description: ' Dolor lacinia? Donec nulla, deleniti, dis arcu pharetra maecenas dapibus ante nemo! Wisi?'
    },
    {
        img: img3,
        title: 'Fortmatic',
        description: 'Potenti eleifend faucibus quo vero nibh netus suspendisse unde? Consectetuer aspernatur'
    },          
    {
        img: img6,
        title: 'Authereum',
        description: 'Purus irure lacinia eiusmod inventore bibendum habitant potenti non sint rem! Felis, asper'
    },
    {
        img: img7,
        title: 'Kaikas',
        description: 'Varius culpa, aspernatur accusantium? Corporis rhoncus, voluptatibus incididunt, velit '
    },
    {
        img: img8,
        title: 'Torus',
        description: ' Soluta fuga nihil, mollitia, ad reprehenderit qui viverra culpa posuere labore inventore'
    },
    
  ]
  

  const {
    library,
    chainId,
    account,
    activate,
    deactivate,
    active
  } = useWeb3React();

  const [signature, setSignature] = useState("");
  const [error, setError] = useState("");
  const [network, setNetwork] = useState(undefined);
  const [message, setMessage] = useState("");
  const [signedMessage, setSignedMessage] = useState("");
  const [verified, setVerified] = useState();

  const handleNetwork = (e) => {
      const id = e.target.value;
      setNetwork(Number(id));
  };

  const refreshState = () => {
      window.localStorage.setItem("provider", undefined);
      setNetwork("");
      setMessage("");
      setSignature("");
      setVerified(undefined);
  }

  const disconnect = () => {
      refreshState();
      deactivate();
  };

  
  const setProvider = (type) => {
    window.localStorage.setItem("provider", type);
  };

  useEffect(() => {
      const provider = window.localStorage.getItem("provider");
      if (provider) activate(connectors[provider]);
  }, []);

  const handleClick = (conn) => {
    activate(connectors[conn]);
    setProvider(conn);
  }

  return (
    <>
      <div className='text-center'>
        <p>
          {`Account: ${truncateAddress(account)}`}
        </p>
        <p>
          {`Network ID: ${chainId ? chainId : "No Network"}`}
        </p>
      </div>
      <ListGroup style={{color:'#000000', fontSize:"1.5rem"}}>
        {
          data.map((item, index) => (
            <ListGroup.Item 
            key={index}
            onClick={() => {handleClick(item.conn)}}
            >
              <Image src={item.img.src} width={30}/>
              <p style={{marginLeft:"1em"}}>{item.title}</p>
            </ListGroup.Item>
          ))
        }
      </ListGroup>
    </>
  )

}

export default Lists;