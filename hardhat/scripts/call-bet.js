require("dotenv").config();
const { getRRPContract, getRequesterContract } = require("./utils");

async function main() {
  console.log(`Calling Bet...`);
  const airnodeRrp = await getRRPContract();
  const requester = await getRequesterContract();
  const { signer } = requester;

  // //    Are we betting that tomorrows price will be above or below todays price
  let { provider } = signer;

  const receipt = await requester.callBet();

  // Wait until the transaction is mined
  const requestId = await new Promise((resolve) =>
    provider.once(receipt.hash, (tx) => {
      const parsedLog = airnodeRrp.interface.parseLog(tx.logs[0]);
      resolve(parsedLog.args.requestId);
    })
  );

  console.log("Made request for todays price:\n", requestId);

  await new Promise((resolve) =>
    provider.once(airnodeRrp.filters.FulfilledRequest(null, requestId), resolve)
  );
  console.log("Fulfilled!");
  let { yesterdaysPrice, above } = await requester.bets(signer.address);
  let todaysPrice = await requester.requestResults(requestId);
  todaysPrice = Number(todaysPrice);
  yesterdaysPrice = Number(yesterdaysPrice);
  // If above is true and todaysPrice is above yesterdaysPrice
  //   or if above is false and todaysPrice is below yesterdaysPrice
  //  then we win
  if (
    (above && todaysPrice > yesterdaysPrice) ||
    (!above && todaysPrice < yesterdaysPrice)
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
