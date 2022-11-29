// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../dependencies/npm/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../dependencies/npm/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./Strings.sol";

/*
    This contract has the ability to do everything in seperate functions
        1. Fund contract
        2. Create Policy
        3. View Policy
        4. Manually update rainfall amount for policy
        5. Make API request to update rainfall amount for policy
        6. Pay or NOT pay policy
    
    TO-DO:
        1. Instead of each being a seperate function, we need to design a function that checks all in a certain order
        2. Have this function used by automation. 
*/
contract TestDataStructure6 is ChainlinkClient, ConfirmedOwner {
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
        @DEV: MANUALLY UPDATE RAIN AMOUNT DATA (FOR TESTING PURPOSES ONLY)
    */
    function updateRainAmountManually (
        string memory _policyId,
        uint256 _rainAmount
    ) public onlyOwner {
        policies[_policyId].rainData.rainAmount = _rainAmount;
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
    ) public onlyOwner {
        uint256 policyRainAmount = policies[_policyId].rainData.rainAmount;
        uint256 policyInsuredAmount = policies[_policyId].insuredAmount;

        require(isPolicy[_policyId] == true);
        require(policies[_policyId].owner != address(0));
        require(policies[_policyId].payment.paid == false);
        require(policies[_policyId].status == PolicyStatus.PENDING);
        require(block.timestamp > policies[_policyId].rainData.endDateUnix);
        require(policyRainAmount < policies[_policyId].minRain || policyRainAmount > policies[_policyId].maxRain);

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
    ) public onlyOwner {
        uint256 policyRainAmount = policies[_policyId].rainData.rainAmount;

        require(isPolicy[_policyId] == true);
        require(policies[_policyId].owner != address(0));
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
        @DEV: FUNCTION TO RETURN BLOCK TIMESTAMP TO UNDERSTAND COMPARISONS
    */
    function getcurrentTimeStamp () public view returns (uint256) {
        return block.timestamp;
    }

    /*
        @DEV: MAKE A CHAINLINK REQUEST (API REQUEST) FOR A CERTAIN POLICY
    */
    function requestTotalRainfall( 
        string memory _policyId,
        address _oracle,
        string memory _jobId        
    ) public onlyOwner {
        
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