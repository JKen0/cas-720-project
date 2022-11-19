// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../dependencies/npm/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../dependencies/npm/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./Strings.sol";

contract WeatherAPITest1 is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY; // 1 * 10**18
    uint256 public totalRainFall1;

    event RequestTotalRainFall1( 
        bytes32 indexed requestId, 
        uint256 indexed _totalRainFall
    );

    constructor() ConfirmedOwner(msg.sender) {
        // hardcoded chainlink token for gorelli network. 
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    }

    function requestTotalRainfall1( 
        address _oracle, 
        string memory _jobId, 
        string memory _lat, 
        string memory _lng, 
        uint256 _startDateUnix, 
        uint256 _endDateUnix 
    ) public onlyOwner {
        
        // create chainlink request
        Chainlink.Request memory req = buildChainlinkRequest( 
            stringToBytes32(_jobId), 
            address(this), 
            this.fulFillTotalRainFall1.selector
        );
        
        // convert the unix values to strings;
        string memory stringStartDate = Strings.toString(_startDateUnix);
        string memory stringEndDate = Strings.toString(_endDateUnix);

        //The URL should look like this: http://localhost:3001/weather/fetchRainfallData?lat=52.1579&lng=106.6702&startDateUnix=1656640184&endDateUnix=1661996984
        string memory apiURL = string(abi.encodePacked("http://host.docker.internal:3001/weather/fetchRainfallData?lat=", _lat, "&lng=", _lng, "&startDateUnix=", stringStartDate, "&endDateUnix=", stringEndDate));

        // add necessary data to the request
        req.add("get", apiURL);
        req.add("path", "sumRainfall");
        req.addInt("times", 10);

        // send chainlink request
        sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    }
    

    function fulFillTotalRainFall1( bytes32 _requestId, uint256 _totalRainFall ) public recordChainlinkFulfillment(_requestId) {
        emit RequestTotalRainFall1(_requestId, _totalRainFall);
        totalRainFall1 = _totalRainFall;
    }


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
}