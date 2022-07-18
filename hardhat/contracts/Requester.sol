//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/* ==================================================================

A simple requester contract that calls Airnode for Stock data.

Users can bet on TSLA stock price being above or below todays price.

The user would use the `makeBet` and `callBet` functions, while
Airnode would handle the results of the bet with the other 2 
functions.

House funds are stored with the contract and must be topped up if empty.
Wins pay 2x the bet amount. 

================================================================== */

contract Requester is RrpRequesterV0, Ownable {
    // Globals
    address public constant airnodeAddress =
        0x5Cd4BaD00e25513B1f86075bC2d066fa68B8512B;
    bytes32 public constant endpointId =
        0xf2c5caa3575e07b81b1d51410953dd083522c06495437acd83255a87647865c7;
    address public sponsorWalletAddress;

    bytes public parameters =
        abi.encode(
            bytes32("1SSSS"),
            bytes32("symbol"),
            "TSLA",
            bytes32("event"),
            "Trade",
            bytes32("_path"),
            "Trade.TSLA.price",
            bytes32("_type"),
            "int256"
        );

    // Mappings
    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => address) public requesterAddresses;
    mapping(address => Bet) public bets;
    mapping(bytes32 => int256) public requestResults;

    struct Bet {
        uint256 amount;
        bool above;
        address player;
        uint256 startTime;
        int256 yesterdaysPrice;
        bool open;
    }


    // Fund the house wallet on deployment
    constructor(address _rrpAddress) payable RrpRequesterV0(_rrpAddress) {
        require(msg.value > 0, "Must send some ether to fund the house wallet");
    }

    function setSponsorWallet(address _sponsorWalletAddress) public onlyOwner {
        sponsorWalletAddress = _sponsorWalletAddress;
    }

    // ============================================================
    // Make a bet on the TSLA price being higher or lower
    // Intended to be called by the player.
    // ============================================================
    function makeBet(bool _above) external payable {
        require(!bets[msg.sender].open, "You already have a bet open");
        require(msg.value >= 0, "Please include your bet amount");
        require(msg.value <= address(this).balance, "House wallet is too low");
        bets[msg.sender] = Bet({
            amount: msg.value,
            above: _above,
            player: msg.sender,
            startTime: block.timestamp,
            yesterdaysPrice: 0,
            open: false
        });
        // Call Airnode to get todays price
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeAddress,
            endpointId,
            address(this),
            sponsorWalletAddress,
            address(this),
            this.fulfillYesterdaysPrice.selector,
            parameters
        );

        // Map the requestId to the address of the requester
        // to be used by Airnode in `fulfillYesterdaysPrice`
        incomingFulfillments[requestId] = true;
        requesterAddresses[requestId] = msg.sender;
    }

    // ============================================================
    // Called by Airnode when the price returned
    // Opens the bet and assigns the price
    // ============================================================
    function fulfillYesterdaysPrice(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
        int256 price = abi.decode(data, (int256));
        requestResults[requestId] = price;
        address requester = requesterAddresses[requestId];
        require(!bets[requester].open, "Bet already opened!");
        bets[requester].open = true;
        bets[requester].yesterdaysPrice = price;
    }

    // ============================================================
    // After the wait period, if the user won, they have the incentive to
    // call their bet and claim their winnings. If they lost, they don't
    // need to do anything, since the funds will stay with the contract.
    // ============================================================
    function callBet() external {
        require(bets[msg.sender].open, "You have no open bets");

        // ============================================================
        // Set your time constraints here.
        // For example, a player can only call their bet between 24 and 26 hours
        // after the start of the bet.
        //
        // For the sake of the example, we'll leave this part out and add 1 case
        // to the results to mock a higher response.
        // ============================================================
        //
        // require(
        //     block.timestamp - bets[msg.sender].startTime >= 1 days,
        //     "You must wait 24 hours before calling your bet"
        // );
        //
        // if (block.timestamp - bets[msg.sender].startTime >= 26 hours) {
        //     bets[msg.sender].open = false;
        //     revert("Your bet has expired");
        // }

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeAddress,
            endpointId,
            address(this),
            sponsorWalletAddress,
            address(this),
            this.closeBet.selector,
            parameters
        );
        incomingFulfillments[requestId] = true;
        requesterAddresses[requestId] = msg.sender;
    }

    // ============================================================
    // Called by Airnode after the `callBet` function.
    // Makes the same API call as `makeBet`, but closes
    // the bet based on the results.
    // ============================================================
    function closeBet(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];

        address requester = requesterAddresses[requestId];
        require(bets[requester].open, "Bet already closed");
        bets[requester].open = false;

        int256 price = abi.decode(data, (int256));

        // Simulates higher price than yesterday
        price += 5;

        requestResults[requestId] = price;

        Bet memory bet = bets[requester];
        if (
            (bet.above && price > bet.yesterdaysPrice) ||
            (!bet.above && price <= bet.yesterdaysPrice)
        ) {
            payable(bet.player).transfer(bet.amount * 2);
        }
    }
}
