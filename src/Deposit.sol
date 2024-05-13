pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositContract is Ownable {
    bool public paused = false;
    bool public refundsAllowed = false;

    uint256 public minDeposit = 0.0069 ether;
    uint256 public maxDeposit = 420 ether;
    uint256 public totalDeposited = 0;

    mapping(address => uint256) public balances;

    modifier whenNotPaused() {
        if (paused) revert DepositPaused();
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);
    event MaxDepositChanged(uint256 newMaxDeposit);
    event MinDepositChanged(uint256 newMinDeposit);
    event SetPaused(bool paused);

    error DepositMinimumError(uint256 minDeposit);
    error DepositPaused();
    error DepositNotPaused();
    error TransferFailed();
    error RefundsNotAllowed();
    error InvalidRefundRequester();

    constructor(address initialOwner, uint256 _minDeposit) Ownable(initialOwner) {
        minDeposit = _minDeposit;
    }

    // Function to deposit ETH into the contract
    function deposit() external payable whenNotPaused {
        if (msg.value < minDeposit) {
            revert DepositMinimumError(minDeposit);
        }

        balances[msg.sender] += msg.value;
        totalDeposited += msg.value;
        emit Deposit(msg.sender, msg.value);

        if (totalDeposited >= maxDeposit) {
            paused = true;
        }
    }

    // Function for users to refund their deposits
    function refund() external {
        if (!refundsAllowed) revert RefundsNotAllowed();

        uint256 _balance = balances[msg.sender];
        if (_balance == 0) revert InvalidRefundRequester();

        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: _balance}("");
        if (!success) revert TransferFailed();

        emit Refund(msg.sender, _balance);
    }

    function balance(address _address) external view returns (uint256) {
        return balances[_address];
    }

    // Function to pause or unpause the deposit process
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;

        emit SetPaused(_paused);
    }

    // Function to pause or unpause the deposit process
    function setRefundsAllowance(bool _refundsAllowed) external onlyOwner {
        if (!paused) revert DepositNotPaused();

        refundsAllowed = _refundsAllowed;
    }

    function setMaxDeposit(uint256 _maxDeposit) external onlyOwner {
        maxDeposit = _maxDeposit;

        emit MaxDepositChanged(_maxDeposit);
    }

    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        minDeposit = _minDeposit;

        emit MinDepositChanged(_minDeposit);
    }

    function withdraw() external onlyOwner {
        if (!paused) revert DepositNotPaused();

        uint256 _amount = address(this).balance;

        (bool success,) = msg.sender.call{value: _amount}("");
        if (!success) revert TransferFailed();

        emit Withdraw(owner(), _amount);
    }
}
