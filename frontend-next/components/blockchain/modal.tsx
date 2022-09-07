
import { Button, Modal, Row, Container} from "react-bootstrap";


import { useWeb3React } from "@web3-react/core";
import { connectors } from "./connectors";

export default function SelectWalletModal({ isOpen, closeModal }) {

  const { activate } = useWeb3React();

  const setProvider = (type) => {
    window.localStorage.setItem("provider", type);
  };

  return (
    <>
      <Modal show={isOpen} onHide={closeModal}>
        <Modal.Header closeButton style={{color: '#000000'}}>
          <Modal.Title>Select Wallet</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Container>
            <Row style={{marginTop:'1em',justifyContent:"center"}}>
              <Button
                style={{width:'80%', fontSize:20}}
                variant = "outline"
                onClick={() => {
                  activate(connectors.coinbaseWallet);
                  setProvider("coinbaseWallet");
                  closeModal();
                }}
              >
                Coinbase Wallet
              </Button>
            </Row>
          
            <Row style={{marginTop:'1em',justifyContent:"center"}}>
              <Button
                style={{width:'80%', fontSize:20}}
                variant = "outline"
                onClick={() => {
                  activate(connectors.walletConnect);
                  setProvider("walletConnect");
                  closeModal();
                }}
              >
                Wallet Connect
              </Button>
            </Row>
            
            <Row style={{marginTop:'1em',justifyContent:"center"}}>
              <Button
                style={{width:'80%', fontSize:20}}
                variant = "outline"
                onClick={() => {
                  activate(connectors.injected);
                  setProvider("injected");
                  closeModal();
                }}
              >
                Metamask
              </Button>
            </Row>
          </Container>
    
          
        </Modal.Body>
        <Modal.Footer>
          {/* <Button variant="secondary" onClick={closeModal}>Close</Button> */}
          {/* <Button variant="primary" onClick={closeModal}>Save changes</Button> */}
        </Modal.Footer>
      </Modal> 
    </>
  );
}
