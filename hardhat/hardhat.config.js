require("dotenv").config();
require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  const wallet = new ethers.Wallet.fromMnemonic(
    process.env.AIRNODE_WALLET_MNEMONIC
  );
  console.log({ address: wallet.mnemonic.phrase });

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.9",
  networks: {
    // hardhat: {
    //   forking: {
    //     url: process.env.PROVIDER_URL,
    //   },
    // },
  },
};
