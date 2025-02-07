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

    // ========================================================
    // Testes para a função safeTransferFrom
    // ========================================================

    // Caminho 1: Transferência bem-sucedida
    function testSafeTransferFrom_Success() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, elias, 1, 5, "");
        
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(elias, 1), 5);
    }

    // Caminho 2: Falha na condição 1 (caller não é owner nem aprovado)
    function testSafeTransferFrom_NotOwnerNorApproved() public {
        vm.prank(elias);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155MissingApprovalForAll(address,address)",
            elias,
            alice
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, elias, 1, 5, "");
    }

    // Caminho 3: Falha na condição 2 (transferência para o endereço zero)
    function testSafeTransferFrom_TransferToZeroAddress() public {
        vm.prank(alice);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155InvalidReceiver(address)",
            zero
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, zero, 1, 5, "");
    }

    // Caminho 4: Falha na condição 3 (saldo insuficiente)
    function testSafeTransferFrom_InsufficientBalance() public {
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

    // Teste adicional: Transferência de quantidade zero
    function testTransferZeroAmount() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, elias, 1, 0, "");
        
        assertEq(token.balanceOf(alice, 1), 10);
        assertEq(token.balanceOf(elias, 1), 0);
    }

    // Teste adicional: Transferência de todos os tokens de um tipo
    function testTransferAllTokens() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, elias, 1, 10, ""); // Transfere todos os 10 tokens do ID 1

        assertEq(token.balanceOf(alice, 1), 0); // Alice não deve ter mais tokens do ID 1
        assertEq(token.balanceOf(elias, 1), 10); // Elias deve receber todos os 10 tokens
    }

    // Teste adicional: Transferência de tokens com ID inexistente
    function testTransferNonExistentToken() public {
        vm.prank(alice);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155InsufficientBalance(address,uint256,uint256,uint256)",
            alice,  // account
            0,      // balance (o ID 3 não existe, então o saldo é 0)
            5,      // needed
            3       // tokenId
        );
        vm.expectRevert(expectedError);
        token.safeTransferFrom(alice, elias, 3, 5, ""); // Tenta transferir 5 tokens do ID 3
    }

    // Teste adicional: Teste de fuzz (entradas aleatórias)
    function testFuzzTransfer(uint256 amount) public {
        // Garante que a quantidade não excede o saldo de Alice
        amount = bound(amount, 0, 10);

        vm.prank(alice);
        token.safeTransferFrom(alice, elias, 1, amount, "");

        assertEq(token.balanceOf(alice, 1), 10 - amount); // Alice deve ter o saldo reduzido
        assertEq(token.balanceOf(elias, 1), amount); // Elias deve receber a quantidade transferida
    }

    // ========================================================
    // Testes para a função safeBatchTransferFrom
    // ========================================================

    // Caminho 1: Pular o laço (array vazio)
    function testSafeBatchTransferFrom_EmptyArray() public {
        uint256[] memory tokenIds = new uint256[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");

        // Verifica que os saldos não mudaram
        assertEq(token.balanceOf(alice, 1), 10);
        assertEq(token.balanceOf(elias, 1), 0);
    }

    // Caminho 2: Executar o laço pelo menos uma vez
    function testSafeBatchTransferFrom_SingleTransfer() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5;

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");

        // Verifica que a transferência foi feita corretamente
        assertEq(token.balanceOf(alice, 1), 5);
        assertEq(token.balanceOf(elias, 1), 5);
    }

    // Teste adicional: Transferência em lote com aprovação
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

    // Teste adicional: Transferência em lote sem aprovação
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

    // Teste adicional: Transferência em lote com IDs inválidos
    function testBatchTransferWithInvalidIds() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 3; // ID 3 não existe

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 5;

        vm.prank(alice);
        bytes memory expectedError = abi.encodeWithSignature(
            "ERC1155InsufficientBalance(address,uint256,uint256,uint256)",
            alice,  // account
            0,      // balance (o ID 3 não existe, então o saldo é 0)
            5,      // needed
            3       // tokenId
        );
        vm.expectRevert(expectedError);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");
    }

    // Teste adicional: Transferência em lote com quantidades zero
    function testBatchTransferWithZeroAmount() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5;
        amounts[1] = 0; // Quantidade zero para o ID 2

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");

        assertEq(token.balanceOf(alice, 1), 5); // Alice deve ter 5 tokens restantes do ID 1
        assertEq(token.balanceOf(alice, 2), 10); // Alice deve manter todos os tokens do ID 2
        assertEq(token.balanceOf(elias, 1), 5); // Elias deve receber 5 tokens do ID 1
        assertEq(token.balanceOf(elias, 2), 0); // Elias não deve receber tokens do ID 2
    }

    // Teste adicional: Transferência em lote com IDs duplicados
    function testBatchTransferWithDuplicateIds() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 1; // ID duplicado

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 5;
        amounts[1] = 5;
        amounts[2] = 5;

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, elias, tokenIds, amounts, "");

        assertEq(token.balanceOf(alice, 1), 0); // Alice deve ter 0 tokens do ID 1 (5 + 5 transferidos)
        assertEq(token.balanceOf(alice, 2), 5); // Alice deve ter 5 tokens do ID 2
        assertEq(token.balanceOf(elias, 1), 10); // Elias deve receber 10 tokens do ID 1
        assertEq(token.balanceOf(elias, 2), 5); // Elias deve receber 5 tokens do ID 2
    }
}