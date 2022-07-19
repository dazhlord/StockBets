<template>
  <v-container>
    <br />
    <v-row justify="center" align="center">
      <v-card elevation="10">
        <v-card-text class="black--text">
          <v-card-title>
            <h1>StockBets</h1>
            <v-btn icon align="start" v-if="walletConnected">
              <v-icon small color="primary" @click="infoDialog = true">
                mdi-information-outline
              </v-icon>
            </v-btn>
            <v-spacer></v-spacer>
            <template v-if="walletConnected">
              House Wallet: {{ houseWalletBalance }} ETH
            </template>
          </v-card-title>
          <v-card-subtitle class="grey--text text--darken-2">
            Tesla Stock Price prediction game powered by DxFeed's public API and
            Airnode
          </v-card-subtitle>

          <v-card-text align="center" justify="center">
            <v-sheet v-if="!walletConnected">
              <v-btn @click="connectWallet" outlined color="primary"
                >Connect Your Wallet</v-btn
              >
            </v-sheet>
            <v-sheet v-else>
              <v-card-title>Bet Details</v-card-title>
              <v-card-text>
                <v-row align="center" justify="center">
                  <v-col cols="12" md="5">
                    <p>I think that TSLA price tomorrow will be</p>

                    <v-select
                      :items="['Higher', 'Lower']"
                      v-model="betDirection"
                      outlined
                      color="primary"
                      :readonly="bet.open || loading"
                    >
                      <template v-slot:selection="{ item }">
                        <span class="d-flex justify-center" style="width: 100%">
                          {{ item }}
                        </span>
                      </template>
                    </v-select>
                    <p>than they are today.</p>
                  </v-col>
                  <v-col cols="12" md="1"> </v-col>
                  <v-col cols="12" md="5" align="center" justify="center">
                    <v-card-text>
                      <v-text-field
                        suffix="ETH"
                        class="amount"
                        color="primary"
                        align="right"
                        label="Bet Amount"
                        outlined
                        :readonly="bet.open || loading"
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
            <v-btn
              :disabled="bet.open || loading"
              @click="makeBet"
              outlined
              color="primary"
            >
              Place Bet
            </v-btn>
            <v-spacer></v-spacer>
            <v-btn
              :disabled="!bet.open || loading"
              @click="callBet"
              outlined
              color="primary"
            >
              Call Bet
            </v-btn>
            <v-spacer></v-spacer>
          </v-card-actions>
        </v-card-text>
      </v-card>
    </v-row>
    <br />
    <br />
    <v-textarea
      label="Request Logs"
      v-if="requestStarted"
      color="primary"
      readonly
      dense
      filled
      :value="logText"
      style="font-family: 'Courier New'"
      :loading="loading"
    />
    <v-dialog v-model="sponsorWalletDialog" max-width="60%">
      <v-card>
        <v-card-title>
          Sponsor Wallet Top Up Required
          <v-spacer></v-spacer>
          <v-btn icon @click="sponsorWalletDialog = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-card-text>
          <v-alert type="error" outlined>
            The Sponsor Wallet for this requester contract is empty. Please
            provide enough gas for Airnode to put it's response on chain.
          </v-alert>
        </v-card-text>

        <v-card-text justify="center" align="center">
          Sponsor Wallet Address: {{ sponsorWalletAddress }}</v-card-text
        >
        <v-card-text>
          <v-row justify="center">
            <v-col cols="12" md="3">
              <v-text-field
                label="Amount"
                outlined
                dense
                :disabled="fundingSponsorWallet"
                suffix="ETH"
                v-model="fundAmount"
                type="number"
              ></v-text-field>
            </v-col>
            <v-col cols="12" md="3">
              <v-btn
                :disabled="fundAmount <= 0"
                @click="fundSponsorWallet"
                :loading="fundingSponsorWallet"
              >
                Fund
              </v-btn>
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>
    </v-dialog>
    <v-dialog max-width="60%" v-model="infoDialog">
      <v-card>
        <v-card-title>
          Snowflake PoC
          <v-spacer></v-spacer>
          <v-btn icon @click="infoDialog = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-card-text>
          This is a Proof of Concept that shows how to make API requests to the
          DxFeed public API from a Smart Contract using
          <a href="https://docs.api3.org/airnode/v0.7/" target="_blank">
            Airnode
            <v-icon x-small> mdi-open-in-new </v-icon>
          </a>

          . Users can bet on their prediction of price tomorrow against price
          today. Airnode will fetch the latest price data from the DxFeed API
          and store them on chain.
          <br />
          <br />
          DxFeed allows us to query
          <a
            href="https://kb.dxfeed.com/en/data-access/rest-api.html"
            target="_blank"
          >
            all kinds of stock data
            <v-icon x-small> mdi-open-in-new </v-icon>
          </a>
          In this case we are querying the Trade data for TSLA stock.
        </v-card-text>

        <v-card-text>
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                label="Sponsor Wallet Address"
                outlined
                readonly
                @focus="$event.target.select()"
                class="address"
                dense
                :value="sponsorWalletAddress"
              >
              </v-text-field>
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                label="House Wallet Address"
                outlined
                color="primary"
                dense
                class="address"
                @focus="$event.target.select()"
                readonly
                :value="requesterAddress"
              >
              </v-text-field>
            </v-col>
          </v-row>
        </v-card-text>
      </v-card>
    </v-dialog>
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
    requestStarted: false,
    bettingContract: null,
    loading: false,
    logText: "",
    sponsorWalletAddress: "",
    sponsorWalletBalance: 0,
    sponsorWalletDialog: false,
    infoDialog: false,
    fundingSponsorWallet: false,
    airnodeRrp: null,
    fundAmount: 0.01,
    houseWalletBalance: null,
    betAmount: 1,
    betDirection: "Higher",
    bet: {},
    RRPAddress: "0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd",
  }),
  computed: {
    requesterAddress() {
      try {
        const json = require("../requesterAddress.json");
        return json.address;
      } catch (error) {
        console.log(error);
        return "0xA04E5B85ecC4Ea2819AfD56feedaCd9219029795";
      }
    },
    requesterAbi() {
      const requesterArtifacts = require("../artifacts/contracts/Requester.sol/Requester.json");
      return requesterArtifacts.abi;
    },
    rrpAbi() {
      const airnodeProtocol = require("@api3/airnode-protocol");
      return airnodeProtocol.AirnodeRrpV0Factory.abi;
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
        const network = await this.provider.getNetwork();
        this.chainId = network.chainId;
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

        this.sponsorWalletAddress =
          await this.bettingContract.sponsorWalletAddress();

        this.sponsorWalletBalance = await this.provider.getBalance(
          this.sponsorWalletAddress
        );

        this.sponsorWalletBalance = ethers.utils.formatEther(
          this.sponsorWalletBalance
        );
        console.log({
          sponsorBalance: ethers.utils
            .parseEther(this.sponsorWalletBalance)
            .toString(),
        });

        this.bet = await this.bettingContract.bets(this.address);
        this.betAmount = ethers.utils.formatEther(this.bet.amount);
        this.betDirection = this.bet.above ? "Higher" : "Lower";
        this.airnodeRrp = new ethers.Contract(
          this.RRPAddress,
          this.rrpAbi,
          this.signer
        );
        console.log(this.bet);
        this.checkSponsorWallet();
        // Connect ethers to metamask
      } catch (error) {
        this.provider = null;
        this.signer = null;
        this.address = null;
        this.chainId = null;
        this.walletConnected = false;
      }
    },
    checkSponsorWallet() {
      const wei = ethers.utils.parseEther(this.sponsorWalletBalance);
      if (wei <= 500000000000000) {
        this.sponsorWalletDialog = true;
        return false;
      } else return true;
    },
    async fundSponsorWallet() {
      this.fundingSponsorWallet = true;
      try {
        const tx = await this.signer.sendTransaction({
          to: this.sponsorWalletAddress,
          value: ethers.utils.parseEther(`${this.fundAmount}`),
        });
        // Wait for tx to be mined
        await tx.wait();
        await this.connectWallet();
        this.sponsorWalletDialog = false;
      } catch (error) {
        console.log(error);
      }
      this.fundingSponsorWallet = false;
    },
    async makeBet() {
      if (!this.checkSponsorWallet()) return;
      this.loading = true;
      this.requestStarted = true;
      try {
        this.printToLog("Making bet...");
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

        this.printToLog("Airnode request made!");
        this.printToLog("RequestId: " + requestId);
        this.printToLog("Waiting for Airnode to respond with stock price...");

        await new Promise((resolve) =>
          provider.once(
            airnodeRrp.filters.FulfilledRequest(null, requestId),
            resolve
          )
        );
        let results = await bettingContract.requestResults(requestId);
        this.printToLog(`The current price for TSLA is ${results}`);
        this.printToLog("Your bet has been placed!\n\n");
        await this.connectWallet();
      } catch (error) {
        this.printToLog(error.message);
      }
      this.loading = false;
    },
    async callBet() {
      if (!this.checkSponsorWallet()) return;
      this.loading = true;

      this.requestStarted = true;
      try {
        this.printToLog("Calling Bet...");
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
        this.printToLog("Airnode request made!");
        this.printToLog("RequestId: " + requestId);
        this.printToLog("Waiting for Airnode to respond with stock price...");

        await new Promise((resolve) =>
          provider.once(
            airnodeRrp.filters.FulfilledRequest(null, requestId),
            resolve
          )
        );
        this.printToLog("Done!\n\n");
        await this.connectWallet();
        let results = await bettingContract.requestResults(requestId);
        const higher = this.bet.yesterdaysPrice < Number(results);
        if ((this.bet.above && higher) || (!this.bet.above && !higher)) {
          this.printToLog(`You won ${this.betAmount} ETH! 🎉`);
          this.printToLog(`Price Yesterday: ${this.bet.yesterdaysPrice}`);
          this.printToLog(`Price Today: ${Number(results)}`);
        } else {
          this.printToLog(`You lost ${this.betAmount} ETH! 😭`);
          this.printToLog(`Price Yesterday: ${this.bet.yesterdaysPrice}`);
          this.printToLog(`Price Today: ${Number(results)}`);
        }
        console.log({ results });
      } catch (error) {
        this.printToLog(error.message);
      }
      this.loading = false;
    },
    printToLog(message) {
      this.logText += `${message}\n`;
    },
  },
};
</script>

<style scoped>
/* Make the .amount bigger */
.amount {
  font-size: 1.5rem;
}
.address {
  font-size: 0.95em;
}
.v-textarea textarea {
  line-height: 400px;
}
</style>
