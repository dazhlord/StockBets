require("dotenv").config();
const hre = require("hardhat");
const airnodeAdmin = require("@api3/airnode-admin");
async function sponsorRequester(requesterAddress) {
  console.log(`Sponsoring Requester: ${requesterAddress}`);
  const mnemonic = process.env.AIRNODE_WALLET_MNEMONIC;
  const providerURL = process.env.PROVIDER_URL;
  //   const requesterAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const airnodeRrpAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  // First obtain the contract instance on target chain

  const airnodeRrp = await airnodeAdmin.getAirnodeRrp(providerURL, {
    signer: { mnemonic },
    airnodeRrpAddress,
  });

  const requester = await airnodeAdmin.sponsorRequester(
    airnodeRrp,
    requesterAddress
  );
  console.log(`Sponsored Requester: ${requesterAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });

module.exports = {
  sponsorRequester,
};
