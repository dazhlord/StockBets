# StockBets

> A Proof-of-Concept that uses Airnode to send API requests from a smart contract to query data directly from DxFeed's public stock price API.

-------

## Under the Hood

![Airnode RRP Flow White](https://user-images.githubusercontent.com/26840412/150416083-f40acb84-fbd6-4d5a-a493-9a7a1a6dc53c.png)

> More detailed [Diagram Here](https://docs.api3.org/airnode/v0.7/grp-developers/call-an-airnode.html)


This PoC illustrates how easy it is to set up a contract to make API calls to an API that is running an Airnode. The process goes like this:

1. An [Airnode RRP contract](https://docs.api3.org/airnode/v0.7/concepts/) has already been deployed by the API3 team on all of the Ethnets. We will be using the [Rinkeby RRP](https://docs.api3.org/airnode/v0.7/reference/airnode-addresses.html#airnoderrp). This is where our Airnode will expect us to put all of our requests.

2. An [Airnode](/airnode) that is configured to read from the RRP from the first step and to call the [DxFeed API](/airnode/config.json) has been deployed to AWS.

3. We have already deployed, and [sponsored](https://docs.api3.org/airnode/v0.7/concepts/sponsor.html#sponsoring-a-requester) our [Betting Contract](/hardhat/contracts/Requester.sol), to allow access to the [gas wallet](https://docs.api3.org/airnode/v0.7/concepts/sponsor.html#sponsorwallet) Airnode will use to return the response on chain. We have hardcoded 1 gas wallet for this PoC. In production, you could allow for each user to have [their own gas wallet](https://docs.api3.org/airnode/v0.7/concepts/sponsor.html#derive-a-sponsor-wallet), but for now anyone can top up this wallet.

4. The [GUI](/frontend) connects to the [Betting Contract](/hardhat/contracts/Requester.sol) from step 3. Since all of the Airnode params are hardcoded into the contract, the end user can interact with the `makeBet` and `callBet` functions without needing any Airnode knowledge.

5. An [Airnode Request](https://docs.api3.org/airnode/v0.7/concepts/request.html#frontmatter-title) is made when using `makeBet` that requests the current TSLA price. The response is stored in a `Bet` struct in the contract. After 24 hours, the user is allowed to call their bet. This will send the same request and compare the price between yesterday and today from the response.

## Structure

- [Hardhat](/hardhat) - All of the Smart Contracts used in this PoC.
- [Airnode](/airnode) - Everything you need to run an Oracle.
- [Front End GUI](/frontend) - For easy interaction with the Betting Contract

## Instructions


If you are attempting to run the code manually/locally, you only really need to do the following:

1. Start up your Airnode

```sh
yarn start-airnode
```

2. 

3. [Start up your Front End GUI](/frontend)


## Recommended Reading

1. [Betting Contract](/hardhat/contracts/Requester.sol) - The Smart Contract that makes the API request. We put the request parameters on chain for immutability.

2. [Airnode Config](/airnode/config/config.json) - Your configuration for Airnode. Contains the mapping of the DxFeed public API endpoints and some chain info. This combined with the [secrets.env](airnode/config/secrets.env) are all you need to run Airnode.

3. [Front End Scripts](/frontend/src/components/dApp.vue) - By including all of the Airnode parameters in the [Betting Contract](/hardhat/contracts/Requester.sol), the end user will only need to provide their bet direction (higher/lower) and their bet value.
