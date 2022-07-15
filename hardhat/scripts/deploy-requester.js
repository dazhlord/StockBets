const { ethers } = require("hardhat");
const fs = require("fs");
const { getParams, fundSponsorWallet, getRRPContract } = require("./utils");

async function main() {
  const Requester = await ethers.getContractFactory("Requester");
  const rrp = await getRRPContract();
  const requester = await Requester.deploy(rrp.address, {
    value: ethers.utils.parseEther(".1"),
  });

  await requester.deployed();

  console.log("Requester deployed to:", requester.address);
  fs.writeFileSync(
    "./scripts/requesterAddress.json",
    JSON.stringify({ address: requester.address })
  );
  fs.writeFileSync(
    "../frontend/src/requesterAddress.json",
    JSON.stringify({ address: requester.address })
  );
  console.log("Address saved to requesterAddress.json");

  const { sponsorWalletAddress } = await getParams();
  console.log(`Setting sponsor wallet address to ${sponsorWalletAddress}`);
  await requester.setSponsorWallet(sponsorWalletAddress);
  console.log("Sponsor wallet address set");
  await fundSponsorWallet();

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
