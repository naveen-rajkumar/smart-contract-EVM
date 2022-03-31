import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "solidity-coverage";
import "hardhat-gas-reporter"
// import '@typechain/hardhat'
// import '@nomiclabs/hardhat-ethers'
// import '@nomiclabs/hardhat-waffle'

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async (args, hre) => {
//   const accounts = await hre.ethers.getSigners();

//   for (const account of accounts) {
//     console.log(await account.address);
//   }
// });

export default {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
    },
  },
  networks:{
    hardhat:{
      gas:20000000,
    }
  },
  gasReporter: {
    enabled: false
  }
};
