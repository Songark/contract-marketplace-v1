require("@nomicfoundation/hardhat-toolbox");
require('hardhat-contract-sizer');
require('@openzeppelin/hardhat-upgrades');

const dotenv = require("dotenv");
dotenv.config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
        optimizer: {
            enabled: true,
            runs: 200,
        },
    },
  },

  networks: {
    hardhat: {

    },

    localhost: {
      chainId: 1337
    },

    rinkeby: {
      url: process.env.RINKEBY_URL,
      accounts: {
        mnemonic: process.env.KEY_MNEMONIC
      }
    },
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    //only: [':ERC20$'],
  },
};
