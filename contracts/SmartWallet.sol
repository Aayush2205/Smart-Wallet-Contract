//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract SmartWallet{
    struct guardian{
        address from;
        uint count;
        bool vote;
    }
    address payable public owner;
    mapping(address=> uint) public allowance ;
    mapping (address => bool) public isAllowedToSend;
    mapping(address => guardian) public guardians; 
    mapping(address => bool) public proposal;
    address payable nextOwner;
    uint public guardiansResetCount;
    uint public guardiansCount;
    uint public constant confirmationsFromGuardiansForReset = 3;

    event GuardianAdded(address indexed _from);
    event SetNewOwner(address indexed _from);
    event SetAllowance(address indexed _from, uint indexed _amount);

    constructor(){
        owner = payable(msg.sender);
    }
    function setGuardian(address _guardian) public {
        require(msg.sender==owner,"Not the Owner");
        require(guardians[_guardian].count!=1,"Already a guardian");
        require(guardiansCount<5," 5 guardian already set");
        guardians[_guardian].from=_guardian;
        guardians[_guardian].count=1;
        guardiansCount++;
        emit GuardianAdded(_guardian);
    }

    function proposeNewOwner(address payable newOwner)public {
        require(guardians[msg.sender].count==1,"Not a guardian");
        require(!guardians[msg.sender].vote, "Already voted");
        require(!proposal[msg.sender],"Already proposed a new owner");
        if(nextOwner != newOwner) {
            nextOwner = newOwner;
            guardiansResetCount = 0;
            proposal[msg.sender]= true;
        }
        guardiansResetCount++;
        guardians[msg.sender].vote=true;
    }
    function voteFornNewOwner(bool _vote)public{
        require(guardians[msg.sender].count==1,"Not a guardian");
        require(!guardians[msg.sender].vote, "Already voted");
        require(!proposal[msg.sender],"Already proposed a new owner");
        guardians[msg.sender].vote= _vote;
        if(guardians[msg.sender].vote== true){
            guardiansResetCount++;
        }
    }
    function setNewOwner() public{
        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
        emit SetNewOwner(owner);
    }
    function resetVote() public{
        require(guardians[msg.sender].count==1,"Not a guardian");
        require(guardians[msg.sender].vote, "No Votes");
        require(proposal[msg.sender],"didn't proposed a new owner");
        guardians[msg.sender].vote = false;
        proposal[msg.sender]= false;
    }

    function setAllowance(address _from, uint _amount) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        allowance[_from] = _amount;
        isAllowedToSend[_from] = true;
        emit SetAllowance(_from, _amount);
    }

    function denySending(address _from) public {
        require(msg.sender == owner, "You are not the owner, aborting!");
        isAllowedToSend[_from] = false;
    }

    function transfer(address payable _to, uint _amount, bytes memory payload) public returns (bytes memory) {
        require(_amount <= address(this).balance, "Can't send more than the contract owns, aborting.");
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send any transactions, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");
            allowance[msg.sender] -= _amount;

        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(payload);
        require(success, "Transaction failed, aborting");
        return returnData;
    }
    receive() external payable{}
}
