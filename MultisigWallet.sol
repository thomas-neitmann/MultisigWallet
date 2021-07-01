pragma solidity 0.7.5;

contract MultisigWallet {
    struct TransferRequest {
        address payable recipient;
        uint amount;
        uint numApprovals;
        bool completed;
    }
    
    event transactionCompleted(address recipient, uint amount);
    
    address[] owners;
    mapping(address => bool) public isOwner;
    mapping(address => mapping(uint => bool)) approvals;
    uint numApprovalsNeeded;
    TransferRequest[] transfers;
    
    constructor(address[] memory _owners, uint _numApprovalsNeeded) {
        require(_owners.length >= 2, "The wallet needs at least two owners");
        require(_numApprovalsNeeded >= 2, "The minimum number of approvals needed in 2");
        
        numApprovalsNeeded = _numApprovalsNeeded;
        owners = _owners;
        for (uint i = 0; i < _owners.length; i++) {
            isOwner[owners[i]] = true;
        }
    }
    
    function deposit() public payable returns(uint) {
        return address(this).balance;
    }
    
    function requestTransfer(address payable recipient, uint amount) public {
        require(isOwner[msg.sender], "Only contract owners can request a transfer");
        require(address(this).balance >= amount, "Wallet balance not sufficient for requested amount");

        transfers.push(TransferRequest(recipient, amount, 1, false));
        approvals[msg.sender][transfers.length] = true;
    }
    
    function approveTransfer(uint txId) public {
        require(isOwner[msg.sender], "Only contract owners can approve a transfer");
        require(!approvals[msg.sender][txId], "Transfer has already been approved by this address");
        require(!transfers[txId].completed, "Transfer has already been completed");
        
        approvals[msg.sender][txId] = true;
        transfers[txId].numApprovals += 1;
        
        if (transfers[txId].numApprovals >= numApprovalsNeeded) {
            require(address(this).balance >= transfers[txId].amount, "Transfer cannot be completed due to insufficient funds");
            
            transfers[txId].recipient.transfer(transfers[txId].amount);
            emit transactionCompleted(transfers[txId].recipient, transfers[txId].amount);
            transfers[txId].completed = true;
        }
    }
    
    function revokeApproval(uint txId) public {
        require(isOwner[msg.sender] && approvals[msg.sender][txId], "Only contract owners who have already approved a transaction can reverse their approval");
        require(!transfers[txId].completed, "Transfer has already been completed");
        
        transfers[txId].numApprovals -= 1;
        approvals[msg.sender][txId] = false;
    }
    
    function getTransfer(uint txId) public view returns(address, uint, uint, bool) {
        return (transfers[txId].recipient, transfers[txId].amount, transfers[txId].numApprovals, transfers[txId].completed);
    }
    
}
