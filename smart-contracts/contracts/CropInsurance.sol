// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../dependencies/npm/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../dependencies/npm/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./Strings.sol";

contract CropInsurance is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY; // 1 * 10**18

    event RequestTotalRainFall( 
        bytes32 indexed requestId, 
        uint256 indexed _totalRainFall
    );

    enum PolicyStatus { PENDING, DO_NOT_PAY, PAID }

    struct RainData {
        uint startDateUnix;
        uint endDateUnix;
        string lat;
        string lng; 
        uint256 rainAmount;
    }

    struct Payment {
        bool paid;
        uint256 amount;
        string txHash;
    }

    struct Policy {
        string policyId;
        PolicyStatus status;
        address payable owner;
        RainData rainData;
        uint256 minRain;
        uint256 maxRain;
        uint256 insuredAmount;
        Payment payment;        
    }

    string[] public arrayPolicyID;
    mapping(string => bool) isPolicy;
    mapping(string => Policy) policies;
    mapping(bytes32 => string) requests;

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    }

    /*
        @DEV: FUNCTION TO CREATE A NEW POLICY GIVEN ALL THE PARAMETERS NEEDED:
    */
    function createNewPolicy(
        string memory _policyId,
        address payable _owner,
        uint _startDateUnix,
        uint _endDateUnix,
        string memory _lat,
        string memory _lng,
        uint256 _minRain,
        uint256 _maxRain,
        uint256 _insuredAmount
    ) public onlyOwner {

        // calculate the liability of this contract insurance
        // this includes all pending policies + the new policy we want to make
        uint256 requiredContractBalance = 0;
        for (uint i=0; i < arrayPolicyID.length; i++) {
            string memory policyId = arrayPolicyID[i]; 
            Policy memory policyData = policies[policyId];

            if(policyData.status == PolicyStatus.PENDING) {
                requiredContractBalance = requiredContractBalance + policyData.insuredAmount;
            }

        }
        requiredContractBalance = requiredContractBalance + _insuredAmount;
        
        // the contract must have enough funds to pay out the new contract when crerating a contract. 
        require(address(this).balance >= requiredContractBalance);

        // create the new policy using the parameters that the user provided:
        Policy memory _newPolicy = Policy(
            _policyId,
            PolicyStatus.PENDING,
            _owner,
            RainData(_startDateUnix, _endDateUnix, _lat, _lng, 0),
            _minRain,
            _maxRain,
            _insuredAmount,
            Payment(false, 0, "")
        );

        // add the policy to our data structure and mark thhat the policy ID does exist in our system
        policies[_newPolicy.policyId] = _newPolicy;
        isPolicy[_newPolicy.policyId] = true;
        arrayPolicyID.push(_newPolicy.policyId);
    }

    /*
        @DEV: FETCH POLICY DATA
    */
    function getPolicyData (
        string memory _policyId
    ) public view returns (Policy memory) {     
        // 1. return policy if it exists
        if (isPolicy[_policyId] == true) {
            Policy memory _policy = policies[_policyId];
            return _policy;
        } 
        
        // 2. return dummy policy if it does not exist
        else {
            Policy memory _dummyPolicy = Policy(
                "DUMMY-POLICY",
                PolicyStatus.PENDING,
                payable(address(0)),
                RainData(1661994625, 1664586625, "51.5072", "0.1276", 0),
                50,
                100,
                1,
                Payment(false, 0, "")
            );
            return _dummyPolicy;
        }  

    }

    /*
        @DEV: GET POLICY RAIN AMOUNT
    */
    function getPolicyRainAmount (
        string memory _policyId
    ) public view returns (uint256) {
        return policies[_policyId].rainData.rainAmount;
    }

    /*
        @DEV: FUNCTION TO PAY OUT A POLICY (IF ALL CONDITIONS ARE MET)
    */
    function markPolicyPay (
        string memory _policyId
    ) private {
        uint256 policyRainAmount = policies[_policyId].rainData.rainAmount;
        uint256 policyInsuredAmount = policies[_policyId].insuredAmount;

        require(isPolicy[_policyId] == true);
        require(policies[_policyId].payment.paid == false);
        require(policies[_policyId].status == PolicyStatus.PENDING);
        require((block.timestamp > policies[_policyId].rainData.endDateUnix && policyRainAmount < policies[_policyId].minRain) || policyRainAmount > policies[_policyId].maxRain);

        policies[_policyId].owner.transfer(policyInsuredAmount);
        policies[_policyId].payment.paid = true;
        policies[_policyId].status = PolicyStatus.PAID;
        policies[_policyId].payment.amount = policyInsuredAmount;        
    }

    /*
        @DEV: FUNCTION TO MARK POLICY AS DO NOT PAY (IF ALL CONDITIONS ARE MET)
    */
    function markPolicyDoNotPay (
        string memory _policyId
    ) private {
        uint256 policyRainAmount = policies[_policyId].rainData.rainAmount;

        require(isPolicy[_policyId] == true);
        require(policies[_policyId].status == PolicyStatus.PENDING);
        require(block.timestamp > policies[_policyId].rainData.endDateUnix);
        require(policyRainAmount >= policies[_policyId].minRain && policyRainAmount <= policies[_policyId].maxRain);

        policies[_policyId].status = PolicyStatus.DO_NOT_PAY;      
    }

    /*
        @DEV: FUNCTION TO GET THE STATUS OF A POLICY
    */
    function getPolicyStatus (
        string memory _policyId
    ) public view returns (PolicyStatus) {
        return policies[_policyId].status;
    }

    /*
        @DEV: MAKE A CHAINLINK REQUEST (API REQUEST) FOR A CERTAIN POLICY
    */
    function requestTotalRainfall( 
        string memory _policyId,
        address _oracle,
        string memory _jobId        
    ) public {
        
        // create chainlink request
        Chainlink.Request memory req = buildChainlinkRequest( 
            stringToBytes32(_jobId), 
            address(this), 
            this.fulFillTotalRainFall.selector
        );
        
        // extract all necessary data to make the url request
        string memory lat = policies[_policyId].rainData.lat;
        string memory lng = policies[_policyId].rainData.lng;
        string memory stringStartDate = Strings.toString(policies[_policyId].rainData.startDateUnix);
        string memory stringEndDate = Strings.toString(policies[_policyId].rainData.endDateUnix);

        //The URL should look like this: http://localhost:3001/weather/fetchRainfallData?lat=52.1579&lng=106.6702&startDateUnix=1656640184&endDateUnix=1661996984
        string memory apiURL = string(abi.encodePacked("http://host.docker.internal:3001/weather/fetchRainfallData?lat=", lat, "&lng=", lng, "&startDateUnix=", stringStartDate, "&endDateUnix=", stringEndDate));

        // add necessary data to the request
        req.add("get", apiURL);
        req.add("path", "sumRainfall");
        req.addInt("times", 100);

        // send chainlink request
        bytes32 requestId = sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);

        requests[requestId] = _policyId;
    }

    /*
        @DEV: UPDATE THE STATE OF THE POLICY FOR RAIN AMOUNT USING API
    */
    function fulFillTotalRainFall( 
        bytes32 _requestId, 
        uint256 _totalRainFall 
    ) public recordChainlinkFulfillment(_requestId) {
        emit RequestTotalRainFall(_requestId, _totalRainFall);       
        string memory policyId = requests[_requestId];
        policies[policyId].rainData.rainAmount = _totalRainFall;

        // when rain amount state is updated, check if a decision needs to be made. 
        refreshPolicyDecision(policyId);
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
        @DEV: REFRESH RAINFALL DATA FOR EACH POLICY
    */
    function refreshAllPolicyRainfall (
        address _oracle,
        string memory _jobId  
    ) public {
        // loop through all contract policies under this insurance contract
        for (uint i=0; i < arrayPolicyID.length; i++) {
            string memory policyId = arrayPolicyID[i]; 
            Policy memory policyData = policies[policyId];

            // if contract is pending, make updates
            if(policyData.status == PolicyStatus.PENDING) {
                // request update to total rainfall amount for the contract
                requestTotalRainfall(policyId, _oracle, _jobId);
            }
        }
    }

    /*
        @DEV: CHECK ALL POLICY TO SEE IF DECISION IS MADE (MAKE SURE TO UPDATE RAINFALL DATA FIRST)
    */
    function refreshPolicyDecision (
        string memory policyId
    ) private {
        Policy memory policyData = policies[policyId];  

        // if contract is pending, make updates
        if(policyData.status == PolicyStatus.PENDING) {
        
            // if contract expired and rain in between min max, close contract and mark to NOT pay.
            if(
                block.timestamp > policies[policyId].rainData.endDateUnix && 
                (policies[policyId].rainData.rainAmount >= policies[policyId].minRain && policies[policyId].rainData.rainAmount <= policies[policyId].maxRain)
            ) {
                markPolicyDoNotPay(policyId);
            }
            // if contract expires and rain less thn minimum, pay out
            // if contract is over the maximum amount of rain, pay out
            else if (
                    (block.timestamp > policies[policyId].rainData.endDateUnix && policies[policyId].rainData.rainAmount < policies[policyId].minRain) ||
                    policies[policyId].rainData.rainAmount > policies[policyId].maxRain
            ) {
                markPolicyPay(policyId);
            }   
        }
    }

    /*
        @DEV: Have the ability fund this contract in order to pay out potential
    */
    receive() external payable {}
}