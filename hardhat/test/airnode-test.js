require("dotenv").config();
const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  deriveSponsorWalletAddress,
  deriveAirnodeXpub,
} = require("@api3/airnode-admin");

describe("Airnode Admin", function () {
  it("Can get wallet credentials", async function () {
    const [account] = await hre.ethers.getSigners();
    const Requester = await ethers.getContractFactory("Requester");
   
    const airnodeWallet = new ethers.Wallet.fromMnemonic(
      process.env.AIRNODE_WALLET_MNEMONIC
    );
    // AirnodeWallet Balance

    const airnodeXpub = await deriveAirnodeXpub(airnodeWallet.mnemonic.phrase);

    const sponsorWalletAddress = await deriveSponsorWalletAddress(
      airnodeXpub,
      airnodeWallet.address,
      airnodeWallet.address
    );

    console.log({
      sponsorWalletAddress,
      airnodeXpub,
      airnodeWallet: airnodeWallet.address,
    });
  });
});
