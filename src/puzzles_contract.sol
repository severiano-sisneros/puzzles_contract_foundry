//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract PuzzleGame {
    struct Puzzle {
        string puzzleType;
        string data;
        address author;
        uint[2] solutionCommitment;
        uint[2] verificationKey;
        uint maxSolvers;
        address [] solvers;
        mapping(address => bool) solverMap;
    }

    uint public puzzleCount = 0;
    mapping(uint => Puzzle) public puzzles;

    function createPuzzle(string calldata puzzleType, string calldata data, uint[2] calldata solutionCommitment, uint256 maxSolvers) public {
        // Initialize a new puzzle
        Puzzle storage newPuzzle = puzzles[puzzleCount];

        // Set puzzle data
        newPuzzle.puzzleType = puzzleType;
        newPuzzle.data = data;
        newPuzzle.author = payable(msg.sender);
        newPuzzle.solutionCommitment = solutionCommitment;
        newPuzzle.verificationKey = [uint(0x0000000000000000000000000000000000000000000000000000000000000001), uint(0x0000000000000000000000000000000000000000000000000000000000000002)];
        newPuzzle.maxSolvers = maxSolvers;

        // Increment contract puzzle count
        puzzleCount++;
    }
    

    function submitProof(uint id, uint[3] calldata proof) public {
        // Get puzzle data from storage
        Puzzle storage puzzle = puzzles[id];

        // Check if puzzle has been solved by the caller
        require(puzzle.solverMap[msg.sender] == false, "Solver has already solved this puzzle");

        // Check that the puzzle is still available to solved
        require(puzzle.solvers.length < puzzle.maxSolvers, "Maximum number of solvers reached");

        // Verify the proof
        require(verifyProof(proof, id), "Proof verification failed"); 

        // Add the solver to the puzzle solvers list
        puzzle.solvers.push(msg.sender);

        // Set the solver as having solved the puzzle
        puzzle.solverMap[msg.sender] = true;
    }

    function verifyProof( uint[3] memory proof, uint puzzleId) internal view returns (bool) {
        // Get puzzle commitment and key from storage
        uint[2] memory solutionCommitment = puzzles[puzzleId].solutionCommitment;
        uint[2] memory g = puzzles[puzzleId].verificationKey;

        // Initialize variables
        uint[2] memory a;
        uint z;

        // Extract A and z from proof
        a[0] = proof[0];
        a[1] = proof[1];
        z = proof[2];

        // Compute Fiat-Shamir challenge, e
        uint e = uint(sha256(abi.encode(g, solutionCommitment, a)));
        
         // lhs = a + [e]solutionCommitment
        solutionCommitment = callBn256ScalarMul(solutionCommitment[0], solutionCommitment[1], e);
        uint[2] memory lhs = callBn256Add(solutionCommitment[0], solutionCommitment[1], a[0], a[1]);

        //rhs = [z]g
        uint[2] memory rhs = callBn256ScalarMul(g[0], g[1], z);
        return (lhs[0] == rhs[0] && lhs[1] == rhs[1]);
    }

    // Bn256Add precompile
    function callBn256Add(uint ax, uint ay, uint bx, uint by) public view returns (uint[2] memory result) {
        uint[4] memory input;
        input[0] = ax;
        input[1] = ay;
        input[2] = bx;
        input[3] = by;
        assembly {
            if iszero(staticcall(gas(), 0x06, input, 0x80, result, 0x40)){
                revert(0,0)
            }
        }
    }

    // Bn256ScalarMul precompile
    function callBn256ScalarMul(uint x, uint y, uint scalar) public view returns (uint[2] memory result) {
        uint[3] memory input;
        input[0] = x;
        input[1] = y;
        input[2] = scalar;
        assembly {
            if iszero(staticcall(gas(), 0x07, input, 0x60, result, 0x40)) {
                revert(0,0)
            }
        }
    }
}

