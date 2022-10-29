// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

contract CrowdFunding{
    mapping(address=>uint) public contributers;
    address public manager;
    uint public minContri;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noofcontributers;

    struct Request{
        string description;
        address payable recipent;
        uint amountNeeded;
        bool completed;
        uint noofVoters;
        mapping(address=>bool) voters; 
    }
    mapping(uint=>Request) public requests;
    uint public noofRequests;

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline; // 10 sec + 3600 (60*60)
        minContri = 100 wei;
        manager = msg.sender;
    }

    function sendEther() payable public {
        require(block.timestamp < deadline, "Deadline has Ended!");
        require(msg.value >= minContri, "Please donate more then the minimum Ethers :) ");

        if(contributers[msg.sender] == 0){
            noofcontributers ++;
        }
        contributers[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public payable{
        require(block.timestamp > deadline && raisedAmount < target);
        require(contributers[msg.sender] > 0,"You are not elegible for refund broooo!");
        address payable user = payable(msg.sender);
        contributers[msg.sender] = 0;
        user.transfer(contributers[msg.sender]);
        noofcontributers --;
    }

    modifier managerOnly(){
        require(msg.sender == manager);
        _;
    }

    function createRequest(string memory _description, uint _amountNeeded, address payable _recipent) managerOnly public {
        Request storage newRequest = requests[noofRequests]; // newRequest -> requets -> Requests 
        noofRequests++;
        newRequest.description = _description;
        newRequest.amountNeeded = _amountNeeded;
        newRequest.recipent = _recipent;
        newRequest.completed = false;
        newRequest.noofVoters = 0;
    }

    function voting(uint _requestNumber) public {
        require(contributers[msg.sender]>0,"Must be a donater first!");
        Request storage voteRequest = requests[_requestNumber];
        require(voteRequest.voters[msg.sender]==false,"You have already voted!");
        voteRequest.voters[msg.sender] = true;
        voteRequest.noofVoters++;
    }

    function makepayment(uint _requestNumber) public managerOnly {
        require(raisedAmount >= target);
        Request storage payment = requests[_requestNumber];
        require(payment.completed == false,"Request has already been completed");
        require(payment.noofVoters > (noofcontributers/2));
        payment.recipent.transfer(payment.amountNeeded);
        payment.completed = true;
    }
}
