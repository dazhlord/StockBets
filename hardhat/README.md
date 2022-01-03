# Smart Contracts

> Here we use [Hardhat](https://hardhat.org/) to manage our Smart Contracts.

You won't need to use this folder in the PoC, since we have already deployed everything needed. We've attached it more for your knowledge.

You also have access to the [scripts](/scripts) we use to manage our Airnode. This folder will give you good insight into the [tools](https://docs.api3.org/airnode/v0.3/reference/packages/admin-cli.html#frontmatter-title) used to secure your Airnode and contracts. We included an example `.env` file for convenience.

## Contract

The [Requester.sol](contracts/Requester.sol) is the main contract for the PoC. It includes a `makeBet` and a `callBet` function that are to be used by the human user. It also includes `fulfillYesterdaysCases` and `closeBet` functions that are [only called by Airnode](https://docs.api3.org/airnode/v0.3/concepts/request.html#fulfill) when it receives a successful response.

All of the [Airnode params](https://docs.api3.org/airnode/v0.3/concepts/request.html#full-request) are hardcoded into the contract, but it would be just as easy to leave those params up to the user. 
