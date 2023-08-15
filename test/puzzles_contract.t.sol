// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PuzzleGame} from "../src/puzzles_contract.sol";

contract PuzzleGameTest is Test {
    PuzzleGame public puzzleGame;

    function setUp() public {
        puzzleGame = new PuzzleGame();
    }

    function test_createPuzzle() public {
        string memory puzzleType = "crossword_type";
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        assertEq(puzzleGame.puzzleCount(), 1);
        // assertEq(puzzleGame.puzzles(1).puzzleType(), "test");
    }

    // test submit proof
    function test_submitProof() public {
        string memory puzzleType = "crossword_type";
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);

        uint puzzleId = 0;
        uint[3] memory puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                                      uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                                      uint(0x023d2d04070d863e73cdc6fb1981c26154d77231c55499e0786cdab3bf8f07ad)];
        puzzleGame.submitProof(puzzleId, puzzleProof);
        
        // assertEq(puzzleGame.puzzles(0).solvers(0), address(this));
    }

    // function testSetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
