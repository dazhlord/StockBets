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
        "select SUM(CASES_TOTAL_PER_100000) AS CASES FROM WHO_DAILY_REPORT WHERE COUNTRY_REGION IS NOT NULL;";

    bytes public parameters =
        abi.encode(
            bytes32("1SSS"),
            bytes32("statement"),
            dailyCasesSQL,
            bytes32("_path"),
            "CASES",
            bytes32("_type"),
            "int256"
        );
    // ============================================================
    // Airnode Params
    // ============================================================
    address public constant airnodeWalletAddress =
        0x4cFe1AD38Ca18807a4d5533FD5556d4d2b73f691;

    address public constant sponsorWalletAddress =
        0x1648cF440ee5b0dA25DFe78E7CBB94668a374c94;

    bytes32 public constant endpointId =
        0xd3e4bdc2aedbdd3a24942b92486d51fdab98a2e1f3bdc5a3297be8752d5654e0;

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
        cases += 1;

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
