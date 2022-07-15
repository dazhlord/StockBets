require("dotenv").config();
const {
  deriveAirnodeXpub,
  deriveSponsorWalletAddress,
} = require("@api3/airnode-admin");
const airnodeProtocol = require("@api3/airnode-protocol");

const { ethers } = require("hardhat");

async function getParams() {
  const airnodeWallet = new ethers.Wallet.fromMnemonic(
    process.env.AIRNODE_WALLET_MNEMONIC
  );

  const airnodeXpub = await deriveAirnodeXpub(airnodeWallet.mnemonic.phrase);
  const requester = await getRequesterContract();
  const sponsorWalletAddress = await deriveSponsorWalletAddress(
    airnodeXpub,
    airnodeWallet.address,
    requester.address
  );

  return { sponsorWalletAddress, airnodeXpub, airnodeWallet };
}

async function fundSponsorWallet() {
  const accounts = await ethers.getSigners();
  const { sponsorWalletAddress } = await getParams();

  const chainId = await ethers.provider
    .getNetwork()
    .then((network) => network.chainId);
  const amount = chainId == 31337 ? "5" : "0.01";
  // Send 2 eth to airnode wallet
  const tx = await accounts[3].sendTransaction({
    to: sponsorWalletAddress,
    value: ethers.utils.parseEther(amount),
  });
  await tx.wait();
  console.log(`Sponsor wallet funded with ${amount} eth`);
}

async function getRRPContract() {
  let { chainId } = await ethers.provider.getNetwork();
  if (chainId == 31337) chainId = 4;
  const [wallet] = await ethers.getSigners();
  return new ethers.Contract(
    airnodeProtocol.AirnodeRrpAddresses[chainId],
    airnodeProtocol.AirnodeRrpV0Factory.abi,
    wallet
  );
}

async function getRequesterContract() {
  const { address } = require("./requesterAddress.json");
  return await ethers.getContractAt("Requester", address);
}

module.exports = {
  getParams,
  fundSponsorWallet,
  getRequesterContract,
  getRRPContract,
};
