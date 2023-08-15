//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./puzzles_lib.sol";

contract PuzzleGame {

    uint public puzzleCount = 0;
    uint[2] public verificationKey = [uint(0x0000000000000000000000000000000000000000000000000000000000000001), uint(0x0000000000000000000000000000000000000000000000000000000000000002)];
    mapping(uint => PuzzleLib.Puzzle) public puzzles;
    mapping(uint => bool) public puzzleSolved;

    function createPuzzle(string calldata puzzleType, string calldata data, uint[2] calldata solutionCommitment, uint256 maxSolvers) public {
        // Initialize a new puzzle
        PuzzleLib.Puzzle storage newPuzzle = puzzles[puzzleCount];

        // Set puzzle data
        uint puzzleDigest = calculatePuzzleDigest(puzzleType, data, msg.sender, solutionCommitment, maxSolvers);
        newPuzzle.puzzleDigest = puzzleDigest;
        newPuzzle.numSolvers = 0;

        // Emit an event indicating that puzzle has been created
        emit PuzzleCreated(puzzleCount, puzzleType, data, msg.sender, solutionCommitment, maxSolvers);

        // Increment contract puzzle count
        puzzleCount++;
    }
    

    function submitProof(uint id, string calldata puzzleType, string calldata data, uint[2] calldata solutionCommitment, uint256 maxSolvers, uint[3] calldata proof) public {
        // Get puzzle data from storage
        PuzzleLib.Puzzle storage puzzle = puzzles[id];
        
        // Check the puzzleDigest
        uint puzzleDigest = calculatePuzzleDigest(puzzleType, data, msg.sender, solutionCommitment, maxSolvers);
        require(puzzle.puzzleDigest == puzzleDigest, "Puzzle digest does not match");

        // Check if puzzle has been solved by the caller
        uint digest = uint(keccak256(abi.encodePacked(msg.sender, id)));
        require(puzzleSolved[digest] == false, "Solver has already solved this puzzle");

        // Check that the puzzle is still available to solved
        require(puzzle.numSolvers < maxSolvers, "Maximum number of solvers reached");

        // Verify the proof
        require(PuzzleLib.verifyProof( solutionCommitment, verificationKey, proof ), "Proof verification failed"); 

        // Emit an event to notify the puzzle has been solved by the caller
        emit PuzzleSolved(id, msg.sender);

        // Increment the number of solvers
        puzzle.numSolvers++;

        // Set the solver as having solved the puzzle
        puzzleSolved[digest] = true;
    }

    function getPuzzle(uint id) public view returns (PuzzleLib.Puzzle memory) {
        return puzzles[id];
    }

    function calculatePuzzleDigest(string calldata puzzleType, string calldata data, address author, uint[2] calldata solutionCommitment, uint256 maxSolvers) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(puzzleType, data, author, solutionCommitment, maxSolvers)));
    }

    // Event to notify when a puzzle with id is created
    event PuzzleCreated(uint256 id, string puzzleType, string data, address author, uint256[2] solutionCommitment, uint256 maxSolvers);

    // Event to notify the puzzle with id has been solved by the caller (solver)
    event PuzzleSolved(uint id, address solver);
}

