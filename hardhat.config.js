require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-deploy-ethers');
require('hardhat-deploy');
require('solidity-coverage');
require('hardhat-contract-sizer');
require('hardhat-gas-reporter');
require('hardhat-abi-exporter');

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
  },
  
  abiExporter: {
    path: './abi',
    runOnCompile: true,
    clear: true,
    flat: true,
    only: [],
    spacing: 2
  },

  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    token: "ETH",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY, 
    gasPriceApi: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice"
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
