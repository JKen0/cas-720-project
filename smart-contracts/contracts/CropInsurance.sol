pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import "chainlink/v0.6/contracts/ChainlinkClient.sol";
import "chainlink/v0.6/contracts/vendor/Ownable.sol";
import { SafeMath as SafeMath_Chainlink } from "chainlink/v0.6/contracts/vendor/SafeMath.sol";

contract CropInsurance is ChainlinkClient, Ownable {
   using SafeMath_Chainlink for uint256;

    // JOB AND ORACLE ID ARE HARDCODED, MIGHT NEED CHANGE FOR DIFFERENT MACHINES
    bytes32 private constant JOB_ID = "6621eb060ebe4e5080032e03f26e3228";
    address private constant ORACLE = 0xC7d001c4165Cdd237C0bE0bd5c2C96aBe334130F;

    bytes jobId;
    uint256 payment;

    enum RequestStatus {
        CREATED, // @dev The user created the policy and the water level hasn't been measured.
        INITIATED, // @dev The smart contract has requested the water level for the policy. Water levels are measured every 24 hours.
        COMPLETED //@dev The smart contract has received the water level value.
    }

    struct RainData {
        uint256 startDate;
        uint256 endDate;
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
        address payable owner;

        RainData rainData;
        uint256 minRain;
        Payment premium;
        Payment payment;        
    }

    mapping(string => bool) isPolicy;
    mapping(string => Policy) policies;
    //mapping(string => Premium) premiums;
    mapping(bytes32 => string) requests;


    constructor(address _link, address _oracle, bytes32 _jobId) public {
        // Set the address for the LINK token for the network.
        if (_link == address(0)) {
            // Useful for deploying to public networks.
            setPublicChainlinkToken();
            setChainlinkOracle(ORACLE);
            jobId = JOB_ID;
            payment = 1 * LINK;
        } else {
            setChainlinkToken(_link);
            setChainlinkOracle(_oracle);
            jobId = _jobId;
            payment = 1;
        }
    }

    // Create a new policy.
    function createNewPolicy(Policy memory _policy) public onlyOwner {

        policies[_policy.policyId] = _policy;
        isPolicy[_policy.policyId] = true;
    }

    // Get policy details.
    function getPolicy(string memory _policyId) public view onlyOwner returns (Policy memory) {
        // return policy if it exists
        if (isPolicy[_policyId] == true) {
            Policy memory _policy = policies[_policyId];
            return _policy;
        } 
        // return dummy policy if it does not exist
        else {
            Policy memory _policy = Policy(
                "DUMMY-POLICY",
                address(0),
                RainData("2022-01-01", "2022-12-31", 521579, 1066702, 0),
                100,
                Payment(false, 0, ""),
                Payment(false, 0, "")
            );
            return _policy;
        }
    }


    // fetch data from out of chain API
    function createRequestTo( string memory _url, string memory _path, bytes4 _callbackFn) private returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest( jobId, address(this), _callbackFn);

        req.add("url", _url);
        req.add("path", _path);
        requestId = sendChainlinkRequest(req, payment);
    }

    // pay policy function
    function payPolicy(string memory _policyId, uint256 amount) public onlyOwner {
        require(isPolicy[_policyId] == true);
        require(policies[_policyId].owner != address(0));
        require(isPolicyActive(policies[_policyId]) == true);
        require(policies[_policyId].payment.paid == false);

        policies[_policyId].owner.transfer(amount);

        policies[_policyId].payment.paid = true;
        policies[_policyId].payment.amount = amount;
    }

    // check if policy is still active
    function isPolicyActive(InsurancePolicy memory _policy) private view returns(bool){
        return now >= _policy.rainData.startDate && now <= _policy.rainData.endDate;
    }

    function() external payable {}
}
