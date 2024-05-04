pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";


contract DepositContract is Ownable {
    bool public paused = false;
    bool public refundsAllowed = false;

    uint public minDeposit = 0.0069 ether;
    uint public maxDeposit = 420 ether;
    uint public totalDeposited = 0;

    mapping(address => uint) public balances;

    // Modifier to check if the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Deposits are paused.");
        _;
    }

    // Event declarations for logging actions
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Refund(address indexed user, uint amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Function to deposit ETH into the contract
    function deposit() external payable whenNotPaused {
        require(msg.value >= minDeposit, "Minimum deposit amount is 0.0069 ETH.");

        balances[msg.sender] += msg.value;
        totalDeposited += msg.value;
        emit Deposit(msg.sender, msg.value);

        if (totalDeposited >= maxDeposit) {
            paused = true;
        }
    }

    function withdraw() external onlyOwner {
        require(paused, "Deposits are not paused.");

        uint256 _amount = address(this).balance;

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Withdrawal failed");

        totalDeposited -= _amount;
        emit Withdraw(owner(), _amount);
    }

    // Function for users to refund their deposits
    function refund() external {
        require(refundsAllowed, "Refunds are not allowed.");

        uint balance = balances[msg.sender];
        require(balance > 0, "You have no funds deposited.");

        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");

        emit Refund(msg.sender, balance);
    }

    function balance(address _address) external view returns (uint) {
        return balances[_address];
    }

    // Function to pause or unpause the deposit process
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    // Function to pause or unpause the deposit process
    function setRefunds(bool _refundsAllowed) external onlyOwner {
        refundsAllowed = _refundsAllowed;
    }

    function setMaxDeposit(uint _maxDeposit) external onlyOwner {
        maxDeposit = _maxDeposit;
    }
}
