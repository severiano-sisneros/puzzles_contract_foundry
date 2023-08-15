//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./puzzles_lib.sol";

contract PuzzleGame {

    uint public puzzleCount = 0;
    mapping(uint => PuzzleLib.Puzzle) public puzzles;
    mapping(uint => bool) public puzzleSolved;

    function createPuzzle(string calldata puzzleType, string calldata data, uint[2] calldata solutionCommitment, uint256 maxSolvers) public {
        // Initialize a new puzzle
        PuzzleLib.Puzzle storage newPuzzle = puzzles[puzzleCount];

        // Set puzzle data
        newPuzzle.puzzleType = puzzleType;
        newPuzzle.data = data;
        newPuzzle.author = payable(msg.sender);
        newPuzzle.solutionCommitment = solutionCommitment;
        newPuzzle.verificationKey = [uint(0x0000000000000000000000000000000000000000000000000000000000000001), uint(0x0000000000000000000000000000000000000000000000000000000000000002)];
        newPuzzle.maxSolvers = maxSolvers;

        // Emit an event indicating that puzzle has been created
        emit PuzzleCreated(puzzleCount);

        // Increment contract puzzle count
        puzzleCount++;
    }
    

    function submitProof(uint id, uint[3] calldata proof) public {
        // Get puzzle data from storage
        PuzzleLib.Puzzle storage puzzle = puzzles[id];

        // Check if puzzle has been solved by the caller
        uint digest = uint(keccak256(abi.encodePacked(msg.sender, id)));
        require(puzzleSolved[digest] == false, "Solver has already solved this puzzle");

        // Check that the puzzle is still available to solved
        require(puzzle.numSolvers < puzzle.maxSolvers, "Maximum number of solvers reached");

        // Verify the proof
        require(PuzzleLib.verifyProof( puzzle.solutionCommitment, puzzle.verificationKey, proof ), "Proof verification failed"); 

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

    // Event to notify when a puzzle with id is created
    event PuzzleCreated(uint id);

    // Event to notify the puzzle with id has been solved by the caller (solver)
    event PuzzleSolved(uint id, address solver);
}

