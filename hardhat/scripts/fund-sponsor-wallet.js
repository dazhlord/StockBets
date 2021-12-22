require("dotenv").config();
const hre = require("hardhat");
const airnodeAdmin = require("@api3/airnode-admin");

async function main() {
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

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
