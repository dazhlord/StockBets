require("dotenv").config();
const { ethers } = require("hardhat");
const { getRRPContract, getRequesterContract } = require("./utils");
async function main() {
  // We get the contract to deploy
  console.log("Making Bet...");
  const airnodeRrp = await getRRPContract();
  const requester = await getRequesterContract();
  const { signer } = requester;

  // //    Are we betting that tomorrows price will be above or below todays price
  const betAbove = true;
  let { provider } = signer;

  const receipt = await requester.makeBet(betAbove, {
    value: ethers.utils.parseEther("0.5"),
  });

  // Wait until the transaction is mined
  const requestId = await new Promise((resolve) =>
    provider.once(receipt.hash, (tx) => {
      const parsedLog = airnodeRrp.interface.parseLog(tx.logs[0]);
      resolve(parsedLog.args.requestId);
    })
  );

  console.log("Request for todays price made:\n", requestId);

  await new Promise((resolve) =>
    provider.once(airnodeRrp.filters.FulfilledRequest(null, requestId), resolve)
  );
  console.log("Fulfilled!");
  let { yesterdaysPrice, above, amount } = await requester.bets(
    signer.address
  );
  amount = ethers.utils.formatEther(amount);
  yesterdaysPrice = Number(yesterdaysPrice);
  const aboveStr = above ? "above" : "below";
  console.log(
    `${amount} Eth Bet placed that tomorrows price will be ${aboveStr} ${yesterdaysPrice}!`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
