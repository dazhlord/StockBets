const { ethers } = require("hardhat");
const { sponsorRequester } = require("./sponsor-requester");
const { fundSponsorWallet } = require("./fund-sponsor-wallet");
const fs = require("fs");

async function main() {
  const Requester = await ethers.getContractFactory("Requester");
  const requester = await Requester.deploy(
    "0xC11593B87f258672b8eB02d9A723a429b15E9E03",
    { value: ethers.utils.parseEther(".1") }
  );

  await requester.deployed();

  console.log("Requester deployed to:", requester.address);

  // console.log("Funding mnemonic wallet...");
  const mnemonic = process.env.AIRNODE_WALLET_MNEMONIC;
  const airnodeWallet = new ethers.Wallet.fromMnemonic(mnemonic);
  // const [account] = await ethers.getSigners();
  //   Send 10 eth to airnodeWallet
  // await account.sendTransaction({
  //   to: airnodeWallet.address,
  //   value: ethers.utils.parseEther("10"),
  // });
  // console.log("Done!");
  await sponsorRequester(requester.address);
  fs.writeFileSync(
    "./scripts/requesterAddress.json",
    JSON.stringify({ address: requester.address })
  );
  console.log("Address saved to requesterAddress.json");
  // await fundSponsorWallet();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
