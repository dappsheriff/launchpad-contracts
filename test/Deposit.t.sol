// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DepositContract} from "../src/Deposit.sol";

contract CounterTest is Test {
    DepositContract public depositContract;

    address public depositUser;

    function setUp() public {
        depositContract = new DepositContract();

        depositUser = address(1);
        vm.deal(depositUser, 1 ether);
    }

    function test_Deposit() public {
        vm.prank(depositUser);

        depositContract.deposit{value: 0.1 ether}();

        assertEq(depositContract.balance(depositUser), 0.1 ether);
    }

}
