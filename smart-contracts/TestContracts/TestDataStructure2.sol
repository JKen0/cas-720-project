// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../dependencies/npm/@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../dependencies/npm/@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./Strings.sol";

contract TestDataStructure3 is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY; // 1 * 10**18
    string private constant JOB_ID = "6621eb060ebe4e5080032e03f26e3228";
    address private constant ORACLE = 0xC7d001c4165Cdd237C0bE0bd5c2C96aBe334130F;

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
        require(policies[_policyId].rainData.endDateUnix > block.timestamp);
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
        require(policies[_policyId].rainData.endDateUnix > block.timestamp);
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

}