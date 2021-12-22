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
    const requester = await Requester.attach(
      "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
    );
    const airnodeWallet = new ethers.Wallet.fromMnemonic(
      "impose again erupt picture special urban stage actor faith response soup desert"
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
