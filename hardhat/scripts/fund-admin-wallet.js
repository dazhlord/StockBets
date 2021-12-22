require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const mnemonic = process.env.AIRNODE_WALLET_MNEMONIC;
  const providerURL = process.env.PROVIDER_URL;
  const [account] = await hre.ethers.getSigners();

  const airnodeWallet = new ethers.Wallet.fromMnemonic(mnemonic);
  // Send 2 eth to airnode wallet
  const tx = await account.sendTransaction({
    to: airnodeWallet.address,
    value: ethers.utils.parseEther("20"),
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
