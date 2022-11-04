require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require('hardhat-contract-sizer');
require('@openzeppelin/hardhat-upgrades');
require('hardhat-deploy-ethers');
require('hardhat-deploy');
require('solidity-coverage');

const dotenv = require("dotenv");
dotenv.config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  react: {
    providerPriority: ["web3modal", "hardhat"],
  },

  paths: {
    "artifacts": './frontend-next/hardhat/artifacts',
  },

  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    token: "ETH",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY, 
    gasPriceApi: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice"
  },
  
  solidity: {
    version: "0.8.4",
    settings: {
        optimizer: {
            enabled: true,
            runs: 200,  // https://github.com/NomicFoundation/hardhat/issues/2657
        },
    },
  },

  networks: {
    hardhat: {

    },

    ethermain: {
      url: process.env.ETH_MAINNET_URL,
      accounts: {
        mnemonic: process.env.KEY_MNEMONIC
      }
    },

    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: {
        mnemonic: process.env.KEY_MNEMONIC
      }
    },

    goerli: {
      url: process.env.GOERLI_URL,
      accounts: {
        mnemonic: process.env.KEY_MNEMONIC
      }
    },

    mumbai: {
      url: process.env.POLYGON_MUMBAI_URL || "",
      accounts: {
        mnemonic: process.env.KEY_MNEMONIC
      }
    },

    polygonmain: {
      url: process.env.POLYGON_MAINNET_URL || "",
      accounts: {
        mnemonic: process.env.KEY_MNEMONIC
      }
    }
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    //only: [':ERC20$'],
  },
};
