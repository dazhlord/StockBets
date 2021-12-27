require("dotenv").config();
const hre = require("hardhat");
const airnodeAdmin = require("@api3/airnode-admin");

async function fundSponsorWallet() {
  const mnemonic = process.env.AIRNODE_WALLET_MNEMONIC;
  const accounts = await hre.ethers.getSigners();
  //   const providerURL = process.env.PROVIDER_URL;
  const airnodeWallet = new ethers.Wallet.fromMnemonic(mnemonic);
  const sponsorWalletAddress = await airnodeAdmin.deriveSponsorWalletAddress(
    airnodeAdmin.deriveAirnodeXpub(mnemonic),
    airnodeWallet.address,
    airnodeWallet.address
  );

  // Send 2 eth to airnode wallet
  const tx = await accounts[1].sendTransaction({
    to: sponsorWalletAddress,
    value: ethers.utils.parseEther("5"),
  });
  console.log(tx);

  console.log("Done!");
}

module.exports = {
  fundSponsorWallet,
};
