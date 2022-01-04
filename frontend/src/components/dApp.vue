<template>
  <v-container>
    <br />
    <v-row justify="center" align="center">
      <v-col cols="12" md="9">
        <v-card elevation="10">
          <v-card-text class="black--text">
            <v-card-title>
              <h1>CovidBets</h1>
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
              Covid cases prediction game powered by Snowflake DB and Airnode
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
                      <p>I think that Covid-19 cases tomorrow will be</p>

                      <v-select
                        :items="['Higher', 'Lower']"
                        v-model="betDirection"
                        outlined
                        color="primary"
                        :readonly="bet.open || loading"
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
      </v-col>
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
          This is a Proof of Concept that shows how to make SQL queries to the
          Snowflake DB from a Smart Contract using
          <a href="https://docs.api3.org/airnode/v0.3/" target="_blank">
            Airnode
            <v-icon x-small> mdi-open-in-new </v-icon>
          </a>

          . Users can bet on their prediction of cases tomorrow against cases
          today. Airnode will fetch the latest cases from the Snowflake DB and
          store them on chain.
          <br />
          <br />
          Snowflake DB allows us to query
          <a href="https://covid19.who.int/table" target="_blank">
            WHO Daily Report
            <v-icon x-small> mdi-open-in-new </v-icon>
          </a>
          data. In this case we are querying the global "Cases - newly reported
          in last 7 days"
        </v-card-text>
        <v-card-text>
          The SQL query hardcoded into the contract is:
          <br />
          <code>
            SELECT SUM(CASES_TOTAL_PER_100000) AS CASES FROM WHO_DAILY_REPORT
            WHERE COUNTRY_REGION IS NOT NULL;
          </code>
        </v-card-text>
        <v-card-text>
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                label="Sponsor Wallet Address"
                outlined
                readonly
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
  }),
  computed: {
    requesterAddress() {
      try {
        const json = require("../../../hardhat/scripts/requesterAddress.json");
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
      const rrpArtifacts = airnodeProtocol.AirnodeRrpFactory;
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
        this.printToLog("Waiting for Airnode to respond with COVID cases...");

        await new Promise((resolve) =>
          provider.once(
            airnodeRrp.filters.FulfilledRequest(null, requestId),
            resolve
          )
        );
        this.printToLog("Your bet has been placed!");
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
        this.printToLog("Waiting for Airnode to respond with COVID cases...");

        await new Promise((resolve) =>
          provider.once(
            airnodeRrp.filters.FulfilledRequest(null, requestId),
            resolve
          )
        );
        this.printToLog("Done!\n\n");
        await this.connectWallet();
        let results = await bettingContract.requestResults(requestId);
        const higher = this.bet.yesterdaysCases < Number(results);
        if ((this.bet.above && higher) || (!this.bet.above && !higher)) {
          this.printToLog(`You won ${this.betAmount} ETH! 🎉`);
          this.printToLog(`Cases Yesterday: ${this.bet.yesterdaysCases}`);
          this.printToLog(`Cases Today: ${Number(results)}`);
        } else {
          this.printToLog(`You lost ${this.betAmount} ETH! 😭`);
          this.printToLog(`Cases Yesterday: ${this.bet.yesterdaysCases}`);
          this.printToLog(`Cases Today: ${Number(results)}`);
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
