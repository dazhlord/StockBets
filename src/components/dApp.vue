<template>
  <v-container>
    <br />
    <br />
    <br />
    <br />
    <br />
    <v-row justify="center" align="center">
      <v-col cols="12" md="9">
        <v-card>
          <v-card-title>
            <h1>CovidBets</h1>
            <v-spacer></v-spacer>
            <template v-if="walletConnected">
              House Wallet: {{ houseWalletBalance }} ETH
            </template>
          </v-card-title>
          <v-card-subtitle>
            Covid cases prediction game powered by Snowflake DB and Airnode
          </v-card-subtitle>

          <v-card-text align="center" justify="center">
            <v-sheet v-if="!walletConnected">
              <v-btn @click="connectWallet">Connect Your Wallet</v-btn>
            </v-sheet>
            <v-sheet v-else>
              <v-card-title>Bet Details</v-card-title>
              <v-card-text>
                <v-row>
                  <v-col cols="12" md="5">
                    <p>
                      I think that Covid-19 cases tomorrow will be
                      <v-select
                        :items="['Higher', 'Lower']"
                        v-model="betDirection"
                      >
                        <template v-slot:selection="{ item }">
                          <span
                            class="d-flex justify-center"
                            style="width: 100%"
                          >
                            {{ item }}
                          </span>
                        </template>
                      </v-select>
                      than they are today.
                    </p>
                  </v-col>
                  <v-col cols="12" md="5">
                    <v-card-text>
                      <v-text-field
                        label="Bet Amount"
                        suffix="ETH"
                        v-model="betAmount"
                        type="number"
                      />
                    </v-card-text>
                  </v-col>
                </v-row>
              </v-card-text>
            </v-sheet>
          </v-card-text>
          <v-card-actions v-if="walletConnected">
            <v-spacer></v-spacer>
            <v-btn :disabled="bet.open" @click="makeBet"> Place Bet </v-btn>
            <v-spacer></v-spacer>
            <v-btn :disabled="!bet.open" @click="callBet"> Call Bet </v-btn>
            <v-spacer></v-spacer>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import { ethers } from "ethers";
export default {
  name: "dApp",

  data: () => ({
    walletConnected: false,
    provider: null,
    signer: null,
    address: null,
    chainId: null,
    bettingContract: null,
    airnodeRrp: null,
    houseWalletBalance: null,
    betAmount: 1,
    betDirection: "Higher",
    bet: {},
  }),
  computed: {
    requesterAddress() {
      return "0x8f86403A4DE0BB5791fa46B8e795C547942fE4Cf";
    },
    requesterAbi() {
      const requesterArtifacts = require("../artifacts/contracts/Requester.sol/Requester.json");
      return requesterArtifacts.abi;
    },
    rrpAbi() {
      const rrpArtifacts = require("../artifacts/@api3/airnode-protocol/contracts/rrp/AirnodeRrp.sol/AirnodeRrp.json");
      return rrpArtifacts.abi;
    },

    RRPAddress() {
      switch (Number(this.chainId)) {
        case 31337:
          return "0x5FbDB2315678afecb367f032d93F642f64180aa3";
        case 4:
          return "0xC11593B87f258672b8eB02d9A723a429b15E9E03";
        default:
          return "0x5FbDB2315678afecb367f032d93F642f64180aa3";
      }
    },
    above() {
      return this.betDirection == "Higher";
    },
  },
  methods: {
    async connectWallet() {
      try {
        this.provider = new ethers.providers.Web3Provider(
          window.ethereum,
          "any"
        );
        // Prompt user for account connections
        await this.provider.send("eth_requestAccounts", []);
        this.signer = this.provider.getSigner();
        this.address = await this.signer.getAddress();
        this.chainId = await this.provider.getNetwork();

        console.log("Account:", this.address);
        this.walletConnected = true;
        this.bettingContract = new ethers.Contract(
          this.requesterAddress,
          this.requesterAbi,
          this.signer
        );
        this.houseWalletBalance = await this.provider.getBalance(
          this.requesterAddress
        );
        this.houseWalletBalance = ethers.utils.formatEther(
          this.houseWalletBalance
        );
        this.bet = await this.bettingContract.bets(this.address);
        this.airnodeRrp = new ethers.Contract(
          this.RRPAddress,
          this.rrpAbi,
          this.signer
        );
        console.log(this.bet);
        // Connect ethers to metamask
      } catch (error) {
        this.provider = null;
        this.signer = null;
        this.address = null;
        this.chainId = null;
        this.walletConnected = false;
      }
    },
    async makeBet() {
      console.log("Betting");
      const { provider, airnodeRrp, bettingContract } = this;
      console.log({ above: this.above });
      const receipt = await bettingContract.makeBet(this.above, {
        value: ethers.utils.parseEther(`${this.betAmount}`),
      });
      // Wait until the transaction is mined
      const requestId = await new Promise((resolve) =>
        provider.once(receipt.hash, (tx) => {
          const parsedLog = airnodeRrp.interface.parseLog(tx.logs[0]);
          resolve(parsedLog.args.requestId);
        })
      );
      console.log("Request made with id:", requestId);
      console.log("Request for todays cases made:\n", requestId);

      await new Promise((resolve) =>
        provider.once(
          airnodeRrp.filters.FulfilledRequest(null, requestId),
          resolve
        )
      );
      console.log("Done!");
      await this.connectWallet();
    },
    async callBet() {
      console.log("Calling Bet");
      const { provider, airnodeRrp, bettingContract } = this;
      console.log({ above: this.above });
      const receipt = await bettingContract.callBet();
      // Wait until the transaction is mined
      const requestId = await new Promise((resolve) =>
        provider.once(receipt.hash, (tx) => {
          const parsedLog = airnodeRrp.interface.parseLog(tx.logs[0]);
          resolve(parsedLog.args.requestId);
        })
      );
      console.log("Request made with id:", requestId);
      console.log("Request for todays cases made:\n", requestId);

      await new Promise((resolve) =>
        provider.once(
          airnodeRrp.filters.FulfilledRequest(null, requestId),
          resolve
        )
      );
      console.log("Done!");
      await this.connectWallet();
    },
  },
};
</script>
