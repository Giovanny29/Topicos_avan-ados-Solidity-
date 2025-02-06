// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MyERC1155.sol";

contract ERC1155CompleteTest is Test {

    MyERC1155 token;
    address alice = address(0x1);
    address elias = address(0x2);
    address morone = address(0x3);
    address zero = address(0);

    function setUp() public {
        token = new MyERC1155();
        token.mint(alice, 1, 10); // Alice recebe 10 tokens do id 1
        token.mint(alice, 2, 10); // Alice recebe 10 tokens do id 2
    }


    // Teste 1: Transferência quando msg.sender == from (caminho direto)
    function testTransferFromOwner() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, elias, 1, 5, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(elias, 1), 5);
    }

    // Teste 2: Transferência com aprovação (caminho com aprovação)
    function testTransferWithApproval() public {
        vm.prank(alice);
        token.setApprovalForAll(elias, true);
        
        vm.prank(elias);
        token.safeTransferFrom(alice, elias, 1, 5, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(elias, 1), 5);
    }

    // Teste 3: Transferência sem aprovação (caminho de falha de aprovação)
    function testTransferWithoutApproval() public {
        vm.prank(elias);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            elias,
            alice
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, elias, 1, 5, "");
    }

    // Teste 4: Transferência com saldo insuficiente (caminho de falha de saldo)
    function testTransferInsufficientBalance() public {
        vm.prank(alice);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155InsufficientBalance(address,uint256,uint256,uint256)",
            alice,  // account
            10,     // balance
            11,     // needed
            1       // tokenId
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, elias, 1, 11, ""); // Tentando transferir 11 quando só tem 10
    }

    // Teste 5: Transferência para endereço zero (caminho de falha de endereço)
    function testTransferToZeroAddress() public {
        vm.prank(alice);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155InvalidReceiver(address)",
            zero
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, zero, 1, 5, "");
    }

    // Teste 6: Revogar aprovação e tentar transferir
    function testRevokeApprovalAndTransfer() public {
        // Primeiro aprova
        vm.prank(alice);
        token.setApprovalForAll(elias, true);
        
        // Depois revoga
        vm.prank(alice);
        token.setApprovalForAll(elias, false);
        
        // Tenta transferir
        vm.prank(elias);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            elias,
            alice
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, elias, 1, 5, "");
    }

    // Teste 7: Transferência de quantidade zero
    function testTransferZeroAmount() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, elias, 1, 0, "");
        
        assertEq(token.balanceOf(alice, 1), 10);
        assertEq(token.balanceOf(elias, 1), 0);
    }

    // Teste 8: Múltiplas aprovações
    function testMultipleApprovals() public {
        vm.prank(alice);
        token.setApprovalForAll(elias, true);
        
        vm.prank(alice);
        token.setApprovalForAll(morone, true);
        
        // elias transfere
        vm.prank(elias);
        token.safeTransferFrom(alice, morone, 1, 3, "");
        
        // morone transfere
        vm.prank(morone);
        token.safeTransferFrom(alice, elias, 1, 3, "");
        
        assertEq(token.balanceOf(alice, 1), 4);
        assertEq(token.balanceOf(elias, 1), 3);
        assertEq(token.balanceOf(morone, 1), 3);
    }

    // Teste 9: Transferência em lote quando msg.sender == from
    function testBatchTransferFromOwner() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 5;

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(alice, 2), 5);
        assertEq(token.balanceOf(elias, 1), 5);
        assertEq(token.balanceOf(elias, 2), 5);
    }

    // Teste 10: Transferência em lote com aprovação
    function testBatchTransferWithApproval() public {
        vm.prank(alice);
        token.setApprovalForAll(elias, true);
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 5;

        vm.prank(elias);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(alice, 2), 5);
        assertEq(token.balanceOf(elias, 1), 5);
        assertEq(token.balanceOf(elias, 2), 5);
    }

    // Teste 11: Transferência em lote sem aprovação
    function testBatchTransferWithoutApproval() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 5;

        vm.prank(elias);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            elias,
            alice
        );
        vm.expectRevert(expectedError);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");
    }
}