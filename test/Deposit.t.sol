// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DepositContract} from "../src/Deposit.sol";

contract DepositTest is Test {
    DepositContract public depositContract;

    address public owner;
    address public depositUser;

    uint256 public minDeposit = 0.0069 ether;

    function setUp() public {
        owner = makeAddr("owner");
        depositContract = new DepositContract(owner, minDeposit);

        depositUser = makeAddr("depositUser");
        vm.deal(depositUser, 1 ether);
    }

    function testDepositSuccess() public {
        vm.prank(depositUser);

        depositContract.deposit{value: 0.1 ether}();

        assertEq(depositContract.balance(depositUser), 0.1 ether);
    }

    function testDepositRequireMinimum() public {
        vm.expectRevert(abi.encodeWithSelector(DepositContract.DepositMinimumError.selector, minDeposit));

        vm.prank(depositUser);
        depositContract.deposit{value: 0.001 ether}();
    }

    function testSetMinDeposit() public {
        vm.prank(owner);
        depositContract.setMinDeposit(1 ether);

        assertEq(depositContract.minDeposit(), 1 ether);

        // Try to deposit with less than the new minimum
        vm.prank(depositUser);
        vm.expectRevert(abi.encodeWithSelector(DepositContract.DepositMinimumError.selector, 1 ether));

        depositContract.deposit{value: 0.1 ether}();
    }

    function testSetMaxDeposit() public {
        vm.prank(owner);
        depositContract.setMaxDeposit(1 ether);

        assertEq(depositContract.maxDeposit(), 1 ether);
    }

    function testSetPaused() public {
        vm.prank(owner);
        depositContract.setPaused(true);

        assert(depositContract.paused());
    }

    function testDepositFailOnPause() public {
        vm.prank(owner);
        depositContract.setPaused(true);

        vm.prank(depositUser);
        vm.expectRevert(abi.encodeWithSelector(DepositContract.DepositPaused.selector));

        depositContract.deposit{value: minDeposit}();
    }

    function testRefund() public {
        vm.prank(depositUser);
        vm.deal(depositUser, 0.1 ether);

        depositContract.deposit{value: 0.1 ether}();
        assertEq(depositContract.balance(depositUser), 0.1 ether);

        vm.startPrank(owner);
        depositContract.setPaused(true);
        depositContract.setRefundsAllowance(true);
        vm.stopPrank();

        vm.prank(depositUser);
        depositContract.refund();

        assertEq(depositContract.balance(depositUser), 0);
        assertEq(address(depositUser).balance, 0.1 ether);
    }

    function testRefundNotAllowed() public {
        vm.prank(depositUser);
        vm.expectRevert(abi.encodeWithSelector(DepositContract.RefundsNotAllowed.selector));

        depositContract.refund();
    }

    function testRefundNoBalance() public {
        vm.startPrank(owner);
        depositContract.setPaused(true);
        depositContract.setRefundsAllowance(true);
        vm.stopPrank();

        vm.prank(depositUser);
        vm.expectRevert(abi.encodeWithSelector(DepositContract.InvalidRefundRequester.selector));

        depositContract.refund();
    }

    function testWithdraw() public {
        vm.prank(depositUser);
        depositContract.deposit{value: 0.1 ether}();

        vm.startPrank(owner);
        depositContract.setPaused(true);
        depositContract.withdraw();
        vm.stopPrank();

        assertEq(address(depositContract).balance, 0);
        assertEq(address(owner).balance, 0.1 ether);
    }

    function testWithdrawNotPaused() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(DepositContract.DepositNotPaused.selector));

        depositContract.withdraw();
    }
}
