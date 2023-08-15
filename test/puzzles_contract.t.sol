// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {PuzzleGame} from "../src/puzzles_contract.sol";
import {PuzzleLib} from "../src/puzzles_lib.sol";

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

        vm.recordLogs();
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        bytes memory encodedPuzzle = abi.encode(uint(0), puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("PuzzleCreated(uint256,string,string,address,uint256[2],uint256)"));
        assertEq(entries[0].data.length, encodedPuzzle.length);
        assertEq(entries[0].data, encodedPuzzle);

        
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(0);
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        assertEq(puzzleGame.puzzleCount(), 1);
        assertEq(puzzle.puzzleDigest, puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
    }
    // test fiat shamir challenge
    function test_fiatShamirChallenge() public {
        uint[2] memory verificationKey = [uint(0x0000000000000000000000000000000000000000000000000000000000000001), 
                                          uint(0x0000000000000000000000000000000000000000000000000000000000000002)];
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint[2] memory a = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                            uint(0x0000000000000000000000000000000000000000000000000000000000000002)];
        uint e = PuzzleLib.fiatShamirChallenge(verificationKey, solutionCommitment, a);

        assertEq(e, 0x09d37f4c7d21480eaa8fe6a4a6d4125ccc8945be34619d9ae3524932a4ef2947);
    }
                      
    // test submitting a "trivial" proof, i.e. no blinding from the solver
    function test_submitTrivialProof() public {
        string memory puzzleType = "crossword_type";
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);

        uint puzzleId = 0;
        uint[3] memory puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                                      uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                                      uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];
        
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(0);
        assertEq(puzzle.numSolvers, 0);
        puzzleGame.submitProof(puzzleId, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        
        puzzle = puzzleGame.getPuzzle(0);
        assertEq(puzzle.numSolvers, 1);
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
        uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
                                      uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
                                      uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(0);
        bytes memory encodedSolve = abi.encode(puzzleId, address(this));

        assertEq(puzzle.numSolvers, 0);
        vm.recordLogs();
        puzzleGame.submitProof(puzzleId, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("PuzzleSolved(uint256,address)"));
        assertEq(entries[0].data.length, encodedSolve.length);
        assertEq(entries[0].data, encodedSolve);

        puzzle = puzzleGame.getPuzzle(0);
        assertEq(puzzle.numSolvers, 1);
    }

    // test submit proof twice by same solver, should fail
    function test_submitProofTwice() public {
        string memory puzzleType = "crossword_type";
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);

        uint puzzleId = 0;
        uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
                                      uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
                                      uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(0);
        assertEq(puzzle.numSolvers, 0);
        puzzleGame.submitProof(puzzleId, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        
        puzzle = puzzleGame.getPuzzle(0);
        assertEq(puzzle.numSolvers, 1);

        vm.expectRevert("Solver has already solved this puzzle");
        puzzleGame.submitProof(puzzleId, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
    }
}
