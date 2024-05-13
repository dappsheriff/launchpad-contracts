// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Test, console} from "forge-std/Test.sol";
import {DepositContract} from "../src/Deposit.sol";
import {TokenClaimContract} from "../src/Airdrop.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Test Token Pls Don't Buy", "TEST") {
        _mint(msg.sender, 100_000_000);
    }
}


contract AirdropTest is Test {
    TokenClaimContract public claimContract;
    MockERC20 public token;
    DepositContract public depositContract;

    address public contractsOwner = makeAddr("owner");
    address public depositUser = makeAddr("depositUser");

    function setUp() public {
        token = new MockERC20();
        depositContract = new DepositContract(contractsOwner, 0.1 ether);

        uint256 mockTokensAllocation = 40_000_000;
        uint256 mockTotalDeposits = 100 ether;

        claimContract = new TokenClaimContract(
            contractsOwner,
            address(token),
            address(depositContract),
            mockTokensAllocation,
            mockTotalDeposits
        );

        token.transfer(address(claimContract), mockTokensAllocation);
    }

    function testClaimTokens() public {
        _setUpDepositUser();
        _setUpClaimsContract();

        vm.prank(depositUser);
        claimContract.claimTokens();

        uint256 expectedTokens = 400_000;  // 1% of the total tokens
        assertEq(token.balanceOf(depositUser), expectedTokens);
    }

    function testClaimTokensAlreadyClaimed() public {
        _setUpDepositUser();
        _setUpClaimsContract();

        vm.startPrank(depositUser);
        claimContract.claimTokens();

        vm.expectRevert(TokenClaimContract.TokensAlreadyClaimed.selector);
        claimContract.claimTokens();

        vm.stopPrank();
    }

    function testClaimTokensNoDeposit() public {
        _setUpClaimsContract();

        vm.prank(depositUser);
        vm.expectRevert(TokenClaimContract.UserNoDeposits.selector);
        claimContract.claimTokens();
    }

    function testClaimTokensNotStarted() public {
        vm.prank(depositUser);
        vm.expectRevert(TokenClaimContract.ClaimNotStarted.selector);
        claimContract.claimTokens();
    }

    /**
     * Helper function to set up the claims contract to be ready for accepting claims
     */
    function _setUpClaimsContract() private {
        vm.startPrank(contractsOwner);
        depositContract.setPaused(true);
        claimContract.setClaimStarted(true);
        vm.stopPrank();
    }

    /**
     * Helper function to set up the deposit user with a deposit
     */
    function _setUpDepositUser() private {
        vm.prank(depositUser);
        vm.deal(depositUser, 1 ether);

        depositContract.deposit{value: 1 ether}();
    }
}
