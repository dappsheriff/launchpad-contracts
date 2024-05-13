// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IDepositContract {
    function balance(address depositor) external view returns (uint256);

    function paused() external view returns (bool);

    function refundsAllowed() external view returns (bool);
}

contract TokenClaimContract is Ownable {
    IERC20 public immutable token;
    IDepositContract public immutable depositContract;
    uint256 public immutable tokensAllocation;
    uint256 public immutable totalDepositsETH;

    bool public claimStarted = false;
    mapping(address => bool) public hasClaimed;

    event TokensClaimed(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);

    error TokensAlreadyClaimed();
    error UserNoDeposits();
    error TransferFailed();
    error DepositNotPaused();
    error DepositRefundsAllowed();
    error ClaimNotStarted();

    constructor(
        address initialOwner,
        address _tokenAddress,
        address _depositContractAddress,
        uint256 _tokensAllocation,
        uint256 _totalDepositsETH
    ) Ownable(initialOwner) {
        token = IERC20(_tokenAddress);
        depositContract = IDepositContract(_depositContractAddress);
        tokensAllocation = _tokensAllocation;
        totalDepositsETH = _totalDepositsETH;
    }

    modifier whenClaimStarted() {
        if (!claimStarted) revert ClaimNotStarted();
        _;
    }

    function claimTokens() public whenClaimStarted {
        _validateDepositContract();

        address user = msg.sender;

        if (hasClaimed[user]) revert TokensAlreadyClaimed();

        uint256 userDeposit = depositContract.balance(user);
        if (userDeposit == 0) revert UserNoDeposits();

        uint256 claimAmount = tokensAllocation * userDeposit / totalDepositsETH;

        hasClaimed[user] = true;
        bool success = token.transfer(user, claimAmount);
        if (!success) revert TransferFailed();

        emit TokensClaimed(user, claimAmount);
    }

    function withdrawTokens() public onlyOwner {
        uint256 remainingTokens = token.balanceOf(address(this));
        bool success = token.transfer(owner(), remainingTokens);
        if (!success) revert TransferFailed();

        emit TokensWithdrawn(owner(), remainingTokens);
    }

    function setClaimStarted(bool _claimStarted) public onlyOwner {
        claimStarted = _claimStarted;
    }

    function _validateDepositContract() private view {
        if (!depositContract.paused()) revert DepositNotPaused();
        if (depositContract.refundsAllowed()) revert DepositRefundsAllowed();
    }
}
