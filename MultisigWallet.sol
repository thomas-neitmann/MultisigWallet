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
    mapping(address => bool) public hasApproved;
    uint numApprovalsNeeded;
    TransferRequest pendingTransfer;
    TransferRequest[] transferLog;
    
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

        hasApproved[msg.sender] = true;
        pendingTransfer = TransferRequest(recipient, amount, 1, false);
    }
    
    function approveTransfer() public {
        require(isOwner[msg.sender], "Only contract owners can approve a transfer");
        require(!hasApproved[msg.sender], "Transfer has already been approved by this address");
        require(!pendingTransfer.completed, "No pending transfer to approve");
        
        pendingTransfer.numApprovals += 1;
        if (pendingTransfer.numApprovals >= numApprovalsNeeded) {
            pendingTransfer.recipient.transfer(pendingTransfer.amount);
            emit transactionCompleted(pendingTransfer.recipient, pendingTransfer.amount);
            transferLog.push(pendingTransfer);
            pendingTransfer.completed = true;
            
            for (uint i = 0; i < owners.length; i++) {
                hasApproved[owners[i]] = false;
            }
            
        }
    }
    
    function reverseApproval() public {
        require(isOwner[msg.sender] && hasApproved[msg.sender], "Only contract owners who have already approved a transaction can reverse their approval");
        pendingTransfer.numApprovals -= 1;
        hasApproved[msg.sender] = false;
    }
    
    function getPendingTransfer() public view returns(address, uint) {
        return (pendingTransfer.recipient, pendingTransfer.amount);
    }
    
}
