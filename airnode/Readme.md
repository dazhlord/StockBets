# CovidBets - Airnode

> [An easy to use, first-party oracle](https://docs.api3.org/airnode/v0.3/)

We have configured an Airnode to read from the Rinkeby Airnode RRP Contract. We deployed that Airnode to our AWS so it can be used by anyone, but you also have the opportunity to run your own Airnode "locally" so you can read the logs. This also adds a layer of redundancy and illustrates how easy popping up oracles should be.

## Configuration

We have already [configured Airnode](https://docs.api3.org/airnode/v0.3/grp-providers/guides/build-an-airnode/configuring-airnode.html#frontmatter-title) to work with the dApp for the PoC. In the [config.json](/config/config.json) you will find all of the chain parameters we will be using, as well as the API Mappings and EndpointIDs we will need to use in our contracts.

> You can find an example [Web3 API Doc Here](https://gist.github.com/gokhanuck/86249dd19cf2808d47bd46c75d5751b4)

The [secrets.env](/config/secrets.env) allows us to remove any secrets from our config.json. this makes it easy to share Airnode configurations without security risks. We have included a `secrets.env` that contains a wallet mnemonic we use for this example PoC for consistency. **In production, you should not publish this file anywhere!**

## Running an Airnode

Running multiple Airnode won't cause any conflict in operation. It is a good idea to run a local Airnode so you can read the logs easily.

You can spin up a local Airnode using the [Container instructions here](https://docs.api3.org/airnode/v0.3/grp-providers/tutorial/quick-deploy-container/#deploy). There is also the option of deploying to [AWS](https://docs.api3.org/airnode/v0.3/grp-providers/tutorial/quick-deploy-aws/#frontmatter-title) or [GCP](https://docs.api3.org/airnode/v0.3/grp-providers/tutorial/quick-deploy-gcp/#frontmatter-title), which would be a requirement in production.

## How does Airnode work?

Your Airnode is configured to check certain contracts for new requests every 1 minute. When it finds a new request, if access has already been granted, it translates that request to a normal REST request and returns the response on chain.  

Data providers retain full control over their Airnode and can redeploy/remove their Airnode on their own if they like. API providers also get access to a ton of [Airnode tools](https://docs.api3.org/airnode/v0.3/reference/packages/admin-cli.html) that allow for extremely granular control over your Airnode and your customers.
