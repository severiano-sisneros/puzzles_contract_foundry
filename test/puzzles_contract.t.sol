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
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;

        vm.recordLogs();
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        // bytes memory encodedPuzzleDigest = abi.encode(puzzleDigest);
        bytes memory encodedPuzzleAuthor = abi.encode(address(this));
        bytes memory encodedPuzzleMetadata = abi.encode(puzzleData,  solutionCommitment, maxSolvers);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length,1);
        assertEq(entries[0].topics.length, 4);
        assertEq(entries[0].topics[0], keccak256("PuzzleCreated(uint256,uint256,string,address,uint256[2],uint256)"));
        assertEq(entries[0].topics[1], bytes32(puzzleDigest));
        assertEq(entries[0].topics[2], bytes32(puzzleType));
        assertEq(entries[0].topics[3], bytes32(encodedPuzzleAuthor));
        assertEq(entries[0].data.length, encodedPuzzleMetadata.length);
        assertEq(entries[0].data, encodedPuzzleMetadata);

        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
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
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);

        uint[3] memory puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                                      uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                                      uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);
    }

    // test submitting a failing proof
    function test_submitFailingProof() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);

        uint[3] memory puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                                      uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                                      uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        vm.expectRevert("Proof verification failed");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
    }


    // test submit proof
    function test_submitProof() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);

        uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
                                      uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
                                      uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);

        assertEq(puzzle.numSolvers, 0);
        address solverAddress = address(0xa);
        bytes memory encodedSolver = abi.encode(solverAddress);
        vm.prank(solverAddress);
        vm.recordLogs();
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length,3);
        assertEq(entries[0].topics[0], keccak256("PuzzleSolved(uint256,address)"));
        assertEq(entries[0].topics[1], bytes32(puzzleDigest));
        assertEq(entries[0].topics[2], bytes32(encodedSolver));

        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);

        (uint solverDigest, bool result) = puzzleGame.checkIfSolverHasSolved(puzzleDigest, solverAddress);
        assertEq(result, true);
        assertEq(solverDigest, uint(keccak256(abi.encodePacked(solverAddress, puzzleDigest))));
    }

    // test replaying a proof
    function test_replayProof() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 2;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);

        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, puzzleAuthor, solutionCommitment, maxSolvers);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);

        uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
                                uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
                                uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];

        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);

        solverAddress = address(0x1);
        vm.prank(solverAddress);
        // vm.expectRevert("Proof verification failed");
        vm.expectRevert("Proof has already been used");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);
    }

    // test submit two different proofs by same solver, should fail
    function test_submitProofTwice() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);

        uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
                                      uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
                                      uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);

        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);

        puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                        uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                        uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];

        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);

        vm.prank(solverAddress);
        vm.expectRevert("Solver has already solved this puzzle");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
    }

    function test_maxSolvers() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);

        uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
                                      uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
                                      uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        
        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        
        
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);

        puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];

        
        vm.prank(address(0x1));
        vm.expectRevert("Maximum number of solvers reached");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
    }

    // test submitting incorrect puzzle data
    function test_submitProofIncorrectDigest() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
                                             uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
        uint maxSolvers = 1;
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        address puzzleAuthor = address(this);

        uint[3] memory puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
                                      uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
                                      uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, puzzleAuthor, solutionCommitment, maxSolvers);
        PuzzleLib.Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        address solverAddress = address(0xa);
        puzzleData = "hints2";
        vm.prank(solverAddress);
        vm.expectRevert("Puzzle digest does not match");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
    }
}
