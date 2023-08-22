// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {PuzzleGame} from "../src/puzzles_contract.sol";
import {Puzzle} from "../src/puzzles_contract.sol";

contract PuzzleGameTest is Test {
    PuzzleGame public puzzleGame;

    function setUp() public {
        puzzleGame = new PuzzleGame();
    }

    function test_createPuzzle() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        address solutionCommitment = 0x07cd18e3CAf84fF010e597Fd0BfD6b4E71893508;

        uint maxSolvers = 1;

        vm.recordLogs();
        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        bytes memory encodedPuzzleAuthor = abi.encode(address(this));
        bytes memory encodedPuzzleMetadata = abi.encode(puzzleData,  solutionCommitment, maxSolvers);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length,1);
        assertEq(entries[0].topics.length, 4);
        assertEq(entries[0].topics[0], keccak256("PuzzleCreated(uint256,uint256,string,address,address,uint256)"));
        assertEq(entries[0].topics[1], bytes32(puzzleDigest));
        assertEq(entries[0].topics[2], bytes32(puzzleType));
        assertEq(entries[0].topics[3], bytes32(encodedPuzzleAuthor));
        assertEq(entries[0].data.length, encodedPuzzleMetadata.length);
        assertEq(entries[0].data, encodedPuzzleMetadata);

        Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.puzzleDigest, puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
    }

    // test ecrecover
    function test_verifySignature() public {
                // puzzleProof = [r, s, v, m_s]
        uint[3] memory puzzleProof = [uint(0xd1e952654d84b4088b861bec0766171ae0e5f4ed2428d0cc6295291843416c5e),
                                      uint(0x08226e269bb30c7ecbdd9dfec595051ac796b38924a49274a734faa94ec7324b), 
                                      uint(0x1b)];
        address m_s = 0x46e69b7c7a696a712528aeAa9f144Fe7E7964Bf3;
        address solutionCommitment = 0x07cd18e3CAf84fF010e597Fd0BfD6b4E71893508;

        assertEq(puzzleGame.verify_signature(m_s, puzzleProof, solutionCommitment), true);
    }

    // test submitting a proof
    function test_submitProof() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint maxSolvers = 1;
        
        address puzzleAuthor = address(this);

                        // puzzleProof = [r, s, v, m_s]
        uint[3] memory puzzleProof = [uint(0xd1e952654d84b4088b861bec0766171ae0e5f4ed2428d0cc6295291843416c5e),
                                      uint(0x08226e269bb30c7ecbdd9dfec595051ac796b38924a49274a734faa94ec7324b), 
                                      uint(0x1b)];
        address m_s = 0x46e69b7c7a696a712528aeAa9f144Fe7E7964Bf3;
        address solutionCommitment = 0x07cd18e3CAf84fF010e597Fd0BfD6b4E71893508;

        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        address solverAddress = m_s;
        vm.prank(solverAddress);
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof, m_s);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);
    }

    // test submitting a failing proof
    function test_submitFailingProof() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint maxSolvers = 1;
        
        address puzzleAuthor = address(this);

                        // puzzleProof = [r, s, v, m_s]
        uint[3] memory puzzleProof = [uint(0xd1e952654d84b4088b861bec0766171ae0e5f4ed2428d0cc6295291843416c5e),
                                      uint(0x08226e269bb30c7ecbdd9dfec595051ac796b38924a49274a734faa94ec7324b), 
                                      uint(0x1b)];
        address m_s = 0x46e69b7c7a696a712528aeAa9f144Fe7E7964Bf3;
        address solutionCommitment = 0x07cd18e3CaF84Ff010e597fD0BFD6B4E71893507; //commitment is wrong by 1 bit

        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        vm.expectRevert("Invalid signature");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof, m_s);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
    }

    // test replaying a proof
    function test_replayProof() public {
        uint puzzleType = uint(0);
        string memory puzzleData = "hints";
        uint maxSolvers = 2;
        
        address puzzleAuthor = address(this);

                        // puzzleProof = [r, s, v, m_s]
        uint[3] memory puzzleProof = [uint(0xd1e952654d84b4088b861bec0766171ae0e5f4ed2428d0cc6295291843416c5e),
                                      uint(0x08226e269bb30c7ecbdd9dfec595051ac796b38924a49274a734faa94ec7324b), 
                                      uint(0x1b)];
        address m_s = 0x46e69b7c7a696a712528aeAa9f144Fe7E7964Bf3;
        address solutionCommitment = 0x07cd18e3CAf84fF010e597Fd0BfD6b4E71893508;

        puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
        
        uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
        Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 0);
        address solverAddress = address(0xa);
        vm.prank(solverAddress);
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof, m_s);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);

        solverAddress = address(0x1);
        vm.prank(solverAddress);
        vm.expectRevert("Proof has already been used");
        puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof, m_s);
        puzzle = puzzleGame.getPuzzle(puzzleDigest);
        assertEq(puzzle.numSolvers, 1);
    }

    // function test_maxSolvers() public {
    //     uint puzzleType = uint(0);
    //     string memory puzzleData = "hints";
    //     uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
    //                                          uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
    //     uint maxSolvers = 1;
    //     puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);

    //     uint[3] memory puzzleProof = [uint(0x0f0fc57fa5f2d70244fb9516b9789429b9f39eaafe35baec27b78cef4f76f408),
    //                                   uint(0x13996c55f0ac2d73f3654822cb2541cea4863a4d7615e12aa75a30f26340d656), 
    //                                   uint(0x15bc5ac0ac210564bce8119fa0ed6324888645e848234d6ff9de3224890f4aee)];
        
    //     uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, address(this), solutionCommitment, maxSolvers);
    //     address puzzleAuthor = address(this);
    //     Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
    //     assertEq(puzzle.numSolvers, 0);
        
    //     address solverAddress = address(0xa);
    //     vm.prank(solverAddress);
    //     puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
        
        
    //     puzzle = puzzleGame.getPuzzle(puzzleDigest);
    //     assertEq(puzzle.numSolvers, 1);

    //     puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
    //             uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
    //             uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];

        
    //     vm.prank(address(0x1));
    //     vm.expectRevert("Maximum number of solvers reached");
    //     puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
    // }

    // // test submitting incorrect puzzle data
    // function test_submitProofIncorrectDigest() public {
    //     uint puzzleType = uint(0);
    //     string memory puzzleData = "hints";
    //     uint[2] memory solutionCommitment = [uint(0x0e074fdf0466838ef0a305e5718b96bd7481e02a5e1106ae7a80236f05db8fb7), 
    //                                          uint(0x192f7ca3094b5962f681bb17e18d9bfad6235aa57f3ea2cc4dcdd6c7335f897c)];
    //     uint maxSolvers = 1;
    //     puzzleGame.createPuzzle(puzzleType, puzzleData, solutionCommitment, maxSolvers);
    //     address puzzleAuthor = address(this);

    //     uint[3] memory puzzleProof = [uint(0x0000000000000000000000000000000000000000000000000000000000000001),
    //                                   uint(0x0000000000000000000000000000000000000000000000000000000000000002), 
    //                                   uint(0x0b8fe2e8c0659b7501b6315a7ccb684766f67f40221968a92ea8872463d27f2e)];
        
    //     uint puzzleDigest = puzzleGame.calculatePuzzleDigest(puzzleType, puzzleData, puzzleAuthor, solutionCommitment, maxSolvers);
    //     Puzzle memory puzzle = puzzleGame.getPuzzle(puzzleDigest);
    //     assertEq(puzzle.numSolvers, 0);
    //     address solverAddress = address(0xa);
    //     puzzleData = "hints2";
    //     vm.prank(solverAddress);
    //     vm.expectRevert("Puzzle digest does not match");
    //     puzzleGame.submitProof(puzzleAuthor, puzzleType, puzzleData, solutionCommitment, maxSolvers, puzzleProof);
    //     puzzle = puzzleGame.getPuzzle(puzzleDigest);
    //     assertEq(puzzle.numSolvers, 0);
    // }

}
