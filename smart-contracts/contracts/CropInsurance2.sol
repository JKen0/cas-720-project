// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../dependencies/npm/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../dependencies/npm/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./Strings.sol";

contract CropInsurance2 is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY; // 1 * 10**18

    enum ALLSTATUS { PENDING, PAID_INSURED, PAID_INSURER }

    event RequestTotalRainFall( 
        bytes32 indexed requestId, 
        uint256 indexed _totalRainFall
    );

    address payable public insurer;
    address payable public insured;
    uint public startDateUnix;
    uint public endDateUnix;
    string public lat;
    string public lng;
    uint256 public rainAmount;
    uint256 public minRain;
    uint256 public maxRain;
    uint256 public insuredAmount;
    ALLSTATUS public contractStatus;


    constructor(
        address payable _insurer,
        address payable _insured,
        uint _startDateUnix,
        uint _endDateUnix,
        string memory _lat,
        string memory _lng,
        uint256 _rainAmount,
        uint256 _minRain,
        uint256 _maxRain,
        uint256 _insuredAmount

    ) ConfirmedOwner(msg.sender) {
        require(_startDateUnix < _endDateUnix);
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);

        insurer = _insurer;
        insured = _insured;
        startDateUnix = _startDateUnix;
        endDateUnix = _endDateUnix;
        lat = _lat;
        lng = _lng;
        rainAmount = _rainAmount;
        minRain = _minRain;
        maxRain = _maxRain;
        insuredAmount = _insuredAmount;
        contractStatus = ALLSTATUS.PENDING;
    }

    /*
        @DEV: FUNCTION TO PAY OUT A POLICY (IF ALL CONDITIONS ARE MET)
    */
    function markPayInsured () private {
        require(contractStatus == ALLSTATUS.PENDING);
        require((block.timestamp > endDateUnix && rainAmount < minRain) || rainAmount > maxRain);


        insured.transfer(insuredAmount);
        contractStatus = ALLSTATUS.PAID_INSURED;    
    }

    /*
        @DEV: FUNCTION TO MARK POLICY AS DO NOT PAY (IF ALL CONDITIONS ARE MET)
    */
    function markPayInsurer () private {
        require(contractStatus == ALLSTATUS.PENDING);
        require(block.timestamp > endDateUnix);
        require(rainAmount >= minRain && rainAmount <= maxRain);

        insurer.transfer(insuredAmount);
        contractStatus = ALLSTATUS.PAID_INSURER;      
    }

    /*
        @DEV: MAKE A CHAINLINK REQUEST (API REQUEST) FOR A CERTAIN POLICY
    */
    function refreshTotalRainfall( address _oracle, string memory _jobId ) public {
        
        // create chainlink request
        Chainlink.Request memory req = buildChainlinkRequest( 
            stringToBytes32(_jobId), 
            address(this), 
            this.fulFillTotalRainFall.selector
        );
        
        // extract all necessary data to make the url request
        string memory stringStartDate = Strings.toString(startDateUnix);
        string memory stringEndDate = Strings.toString(endDateUnix);

        //The URL should look like this: http://localhost:3001/weather/fetchRainfallData?lat=52.1579&lng=106.6702&startDateUnix=1656640184&endDateUnix=1661996984
        string memory apiURL = string(abi.encodePacked("http://host.docker.internal:3001/weather/fetchRainfallData?lat=", lat, "&lng=", lng, "&startDateUnix=", stringStartDate, "&endDateUnix=", stringEndDate));

        // add necessary data to the request
        req.add("get", apiURL);
        req.add("path", "sumRainfall");
        req.addInt("times", 100);

        // send chainlink request
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }

    /*
        @DEV: CHECK ALL POLICY TO SEE IF DECISION IS MADE (MAKE SURE TO UPDATE RAINFALL DATA FIRST)
    */
    function refreshPolicyDecision() public onlyOwner {
        // if contract is pending, make updates
        if(contractStatus == ALLSTATUS.PENDING) {
            
            // if contract expired and rain in between min max, close contract and mark to NOT pay.
            if( block.timestamp > endDateUnix && (rainAmount >= minRain && rainAmount <= maxRain) ) {
                markPayInsurer();
            }
            // if contract expires and rain less thn minimum, pay out
            // if contract is over the maximum amount of rain, pay out
            else if ( (block.timestamp > endDateUnix && rainAmount < minRain) || rainAmount > maxRain ) {
                markPayInsured();
            }   
        }
    }

    /*
        @DEV: UPDATE THE STATE OF THE POLICY FOR RAIN AMOUNT USING API
    */
    function fulFillTotalRainFall( bytes32 _requestId, uint256 _totalRainFall ) public recordChainlinkFulfillment(_requestId) {
        emit RequestTotalRainFall(_requestId, _totalRainFall);
        rainAmount = _totalRainFall;

        // when rain amount state is updated, check if a decision needs to be made. 
        refreshPolicyDecision();
    }

    /*
        @DEV: CONVERT JOB ID TO BYTES WHIC HIS WHAT CHAINLLINK ACCEPTS
    */
    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }


    /*
        @DEV: Have the ability fund this contract in order to pay out potential
    */
    receive() external payable {}
}