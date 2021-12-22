require("dotenv").config();
const hre = require("hardhat");
const airnodeAdmin = require("@api3/airnode-admin");
const { encode } = require("@api3/airnode-abi");
async function main() {
  console.log(`Calling Bet...`);
  // We get the contract to deploy
  const [account] = await hre.ethers.getSigners();

  const { address: requesterAddress } = require("./requesterAddress.json");

  //   const requesterAddress = "0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1";

  const airnodeRrp = await hre.ethers.getContractAt(
    "AirnodeRrp",
    "0x5fbdb2315678afecb367f032d93f642f64180aa3"
  );

  const providerURL = process.env.PROVIDER_URL;
  const provider = new ethers.providers.JsonRpcProvider(providerURL);
  let requester = await hre.ethers.getContractAt("Requester", requesterAddress);

  const bet = await requester.bets(account.address);
  console.log({ open: bet.open, cases: Number(bet.yesterdaysCases) });

  const params = [];

  const receipt = await requester.callBet(encode(params));

  // Wait until the transaction is mined
  const requestId = await new Promise((resolve) =>
    provider.once(receipt.hash, (tx) => {
      const parsedLog = airnodeRrp.interface.parseLog(tx.logs[0]);
      resolve(parsedLog.args.requestId);
    })
  );

  console.log("Made request for todays cases:\n", requestId);

  await new Promise((resolve) =>
    provider.once(airnodeRrp.filters.FulfilledRequest(null, requestId), resolve)
  );
  console.log("Fulfilled!");
  let { yesterdaysCases, above } = await requester.bets(account.address);
  let todaysCases = await requester.requestResults(requestId);
  todaysCases = Number(todaysCases);
  yesterdaysCases = Number(yesterdaysCases);
  //   console.log({ open, cases: Number(yesterdaysCases) });
  // If above is true and todaysCases is above yesterdaysCases
  //   or if above is false and todaysCases is below yesterdaysCases
  //  then we win
  if (
    (above && todaysCases > yesterdaysCases) ||
    (!above && todaysCases < yesterdaysCases)
  ) {
    console.log("You won!");
  } else {
    console.log("You lost!");
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
