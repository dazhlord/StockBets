//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequester.sol";

/* ==================================================================

A simple requester contract that calls Airnode for Covid data.

Users can bet on the cases of Covid-19 being higher or lower
over the next 24 hours. 

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
    // string public dailyCasesSQL =
    //     "SELECT SUM(CONFIRMED) FROM JHU_DASHBOARD_COVID_19_GLOBAL WHERE COUNTRY_REGION = 'United States' AND PROVINCE_STATE = 'California';";

    // bytes public parameters =
    //     abi.encode(
    //         bytes32("1BSabiuBa"),
    //         bytes32("statement"),
    //         dailyCasesSQL,
    //     );
    // ============================================================
    // Airnode Params
    // ============================================================
    address public constant airnodeWalletAddress =
        0x251B60BAb5a32522183427b160E7c07A1F2F1c02;

    address public constant sponsorWalletAddress =
        0xBaCbB77a52fA79309611bAe3b15426129740f43b;

    bytes32 public constant endpointId =
        0xe13847f03ae6d0b93db6ba57d0dcb7456285d7f8f3cfb2feef13eaeaa26a5907;

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
    function makeBet(bool _above, bytes calldata parameters) external payable {
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
        bets[requester].open = true;
        bets[requester].yesterdaysCases = cases;
    }

    // ============================================================
    // After the wait period, if the user won, they have the incentive to
    // call their bet and claim their winnings. If they lost, they don't
    // need to do anything, since the funds will stay with the contract.
    // ============================================================
    function callBet(bytes calldata parameters) external {
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
        int256 cases = abi.decode(data, (int256));

        // Simulates higher cases than yesterday
        cases += 1000;

        requestResults[requestId] = cases;

        address requester = requesterAddresses[requestId];
        bets[requester].open = false;
        Bet memory bet = bets[requester];
        if (
            (bet.above && cases > bet.yesterdaysCases) ||
            (!bet.above && cases <= bet.yesterdaysCases)
        ) {
            payable(bet.player).transfer(bet.amount * 2);
        }
    }
}
