//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequester.sol";

/* ==================================================================

A simple requester contract that calls Airnode for Covid data.

Users can bet on the daily cases of Covid-19 today being above or below
the daily cases 24 hours from the initial bet. 

The user would use the `makeBet` and `callBet` functions, while
Airnode would handle the results of the bet with the other 2 
functions.

House funds are stored with the contract and must be topped up if empty.
Wins pay 2x the bet amount. 

================================================================== */

contract Requester is RrpRequester {
    struct Bet {
        uint256 amount;
        bool above;
        address player;
        uint256 startTime;
        int256 yesterdaysCases;
        bool open;
    }

    // ============================================================
    // The API takes in an SQL statement in the POST body
    // ============================================================
    string public constant dailyCasesSQL =
        "SELECT SUM(CONFIRMED) FROM JHU_DASHBOARD_COVID_19_GLOBAL WHERE COUNTRY_REGION = 'United States' AND PROVINCE_STATE = 'California';";

    bytes public parameters =
        abi.encode(bytes32("1S"), bytes32("statement"), dailyCasesSQL);
    // ============================================================
    // Airnode Params
    // ============================================================
    address public constant airnodeWalletAddress =
        0x251B60BAb5a32522183427b160E7c07A1F2F1c02;

    address public constant sponsorWalletAddress =
        0xBaCbB77a52fA79309611bAe3b15426129740f43b;

    bytes32 public constant endpointId =
        0x7d11ecb8aa6482478859a752bb4c213b91b4bef230e47784b945200ec18d4ac5;

    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => address) public requesterAddresses;
    mapping(address => Bet) public bets;
    mapping(bytes32 => int256) public requestResults;

    // Fund the house wallet on deployment
    constructor(address airnodeAddress) payable RrpRequester(airnodeAddress) {
        require(msg.value > 0, "Must send some ether to fund the house wallet");
    }

    // ============================================================
    // Make a bet on the cases of Covid-19 being higher or lower
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
            yesterdaysCases: 0,
            open: false
        });
        // Call Airnode to get todays Covid cases
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeWalletAddress,
            endpointId,
            airnodeWalletAddress,
            sponsorWalletAddress,
            address(this),
            this.fulfillYesterdaysCases.selector,
            parameters
        );

        // Map the requestId to the address of the requester
        // to be used by Airnode in `fulfillYesterdaysCases`
        incomingFulfillments[requestId] = true;
        requesterAddresses[requestId] = msg.sender;
    }

    // ============================================================
    // Called by Airnode when the Covid cases are returned
    // Opens the bet and assigns the number of cases
    // ============================================================
    function fulfillYesterdaysCases(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
        int256 cases = abi.decode(data, (int256));
        requestResults[requestId] = cases;
        address requester = requesterAddresses[requestId];
        require(!bets[requester].open, "Bet already opened!");
        bets[requester].open = true;
        bets[requester].yesterdaysCases = cases;
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
        // For example, must be between 24 and 26 hours after the start of the bet.
        // ============================================================

        // Set a window for users to claim their winnings or else the
        // house keeps their funds.

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeWalletAddress,
            endpointId,
            airnodeWalletAddress,
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

        int256 cases = abi.decode(data, (int256));

        // Simulates higher cases than yesterday
        cases += 1000;

        requestResults[requestId] = cases;

        Bet memory bet = bets[requester];
        if (
            (bet.above && cases > bet.yesterdaysCases) ||
            (!bet.above && cases <= bet.yesterdaysCases)
        ) {
            payable(bet.player).transfer(bet.amount * 2);
        }
    }
}
