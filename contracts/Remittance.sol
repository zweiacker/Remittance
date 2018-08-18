pragma solidity ^0.4.23;

contract Remittance {
    
    address public owner;

    struct Transferal {
        address transferTo;
        bytes32 doubleHash;
        uint value;
        bool isOpen;
    }    
    
    mapping (bytes32 => Transferal) public transferals;
    // bytes32[] public transferalsIndex;

    event loaded (address beneficiary, bytes32 doubled_hash, bytes32 location, uint amount);
    event unloaded (address beneficiary, bytes32 doubled_hash, bytes32 location);
    event released (bytes32 hash_one, bytes32 hash_two, bytes32 location, address beneficiary, uint amount, bool open);

    constructor() public {
        owner = msg.sender;
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function loadTransfer (address _beneficiary, bytes32 _doubleHash) public isOwner payable {
        require(_doubleHash != 0);
        require(_beneficiary != 0);
        Transferal memory newTransferal;
        newTransferal.transferTo = _beneficiary;
        newTransferal.doubleHash = _doubleHash;
        newTransferal.value = msg.value;
        newTransferal.isOpen = true;

        bytes32 locHash = keccak256(_doubleHash, _beneficiary);
        transferals[locHash] = newTransferal;
        emit loaded (_beneficiary, _doubleHash, locHash, msg.value);
    }
    
    function unloadTransfer(address _beneficiary, bytes32 _doubleHash) public isOwner {
        require(_doubleHash != 0);
        require(_beneficiary != 0);        
        bytes32 locHash = keccak256(_doubleHash, _beneficiary);
        transferals[locHash].isOpen = false;
        owner.transfer(transferals[locHash].value);
        transferals[locHash].value = 0; // just to make sure
        emit unloaded (_beneficiary, _doubleHash, locHash);
    }
    
    function releaseTransfer(bytes32 _hash1, bytes32 _hash2) public {
        bytes32 dHash = keccak256(_hash1, _hash2);
        bytes32 locHash = keccak256(dHash, msg.sender);
        require (transferals[locHash].transferTo == msg.sender);
        require (transferals[locHash].isOpen);
        require (transferals[locHash].doubleHash == dHash);        
        transferals[locHash].isOpen = false;
        msg.sender.transfer(transferals[locHash].value);
        transferals[locHash].value = 0; // just to make sure
        emit released (_hash1, _hash2, locHash, msg.sender, transferals[locHash].value, transferals[locHash].isOpen);
    }
    
    function kill () public isOwner {
        selfdestruct(owner);
    }
}

