// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MyERC1155.sol";

contract ERC1155CompleteTest is Test {
    MyERC1155 token;
    address alice = address(0x1);
    address bob = address(0x2);
    address charlie = address(0x3);
    address zero = address(0);

    function setUp() public {
        token = new MyERC1155();
        token.mint(alice, 1, 10); // Alice recebe 10 tokens do id 1
    }

    // Teste 1: Transferência quando msg.sender == from (caminho direto)
    function testTransferFromOwner() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, bob, 1, 5, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(bob, 1), 5);
    }

    // Teste 2: Transferência com aprovação (caminho com aprovação)
    function testTransferWithApproval() public {
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        
        vm.prank(bob);
        token.safeTransferFrom(alice, bob, 1, 5, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(bob, 1), 5);
    }

    // Teste 3: Transferência sem aprovação (caminho de falha de aprovação)
    function testTransferWithoutApproval() public {
        vm.prank(bob);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            bob,
            alice
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, bob, 1, 5, "");
    }

    // Teste 4: Transferência com saldo insuficiente (caminho de falha de saldo)
    function testTransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("ERC1155: insufficient balance for transfer");
        token.safeTransferFrom(alice, bob, 1, 11, ""); // Tentando transferir 11 quando só tem 10
    }

    // Teste 5: Transferência para endereço zero (caminho de falha de endereço)
    function testTransferToZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert("ERC1155: transfer to the zero address");
        token.safeTransferFrom(alice, zero, 1, 5, "");
    }

    // Teste 6: Revogar aprovação e tentar transferir
    function testRevokeApprovalAndTransfer() public {
        // Primeiro aprova
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        
        // Depois revoga
        vm.prank(alice);
        token.setApprovalForAll(bob, false);
        
        // Tenta transferir
        vm.prank(bob);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            bob,
            alice
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, bob, 1, 5, "");
    }

    // Teste 7: Transferência de quantidade zero
    function testTransferZeroAmount() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, bob, 1, 0, "");
        
        assertEq(token.balanceOf(alice, 1), 10);
        assertEq(token.balanceOf(bob, 1), 0);
    }

    // Teste 8: Múltiplas aprovações
    function testMultipleApprovals() public {
        vm.prank(alice);
        token.setApprovalForAll(bob, true);
        
        vm.prank(alice);
        token.setApprovalForAll(charlie, true);
        
        // Bob transfere
        vm.prank(bob);
        token.safeTransferFrom(alice, charlie, 1, 3, "");
        
        // Charlie transfere
        vm.prank(charlie);
        token.safeTransferFrom(alice, bob, 1, 3, "");
        
        assertEq(token.balanceOf(alice, 1), 4);
        assertEq(token.balanceOf(bob, 1), 3);
        assertEq(token.balanceOf(charlie, 1), 3);
    }
}