//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import "./puzzles_lib.sol";


struct Puzzle {
    uint puzzleDigest;
    uint numSolvers;
}

contract PuzzleGame {
    uint[2] public verificationKey = [uint(0x0000000000000000000000000000000000000000000000000000000000000001), uint(0x0000000000000000000000000000000000000000000000000000000000000002)];
    mapping(uint => Puzzle) public puzzles;
    mapping(uint => bool) public proofUsed;
    mapping(uint => bool) public puzzleSolved;

    function createPuzzle(uint puzzleType, string calldata data, address solutionCommitment, uint256 maxSolvers) public {
        
        uint puzzleDigest = calculatePuzzleDigest(puzzleType, data, msg.sender, solutionCommitment, maxSolvers);

        // Initialize a new puzzle
        Puzzle storage newPuzzle = puzzles[puzzleDigest];

        // Set puzzle data
        newPuzzle.puzzleDigest = puzzleDigest;
        newPuzzle.numSolvers = 0;

        // Emit an event indicating that puzzle has been created
        emit PuzzleCreated(puzzleDigest, puzzleType, data, msg.sender, solutionCommitment, maxSolvers);
    }
    
    function submitProof(address author, uint puzzleType, string calldata data, address solutionCommitment, uint256 maxSolvers, uint[3] calldata proof, address m_s) public {
         uint puzzleDigest = calculatePuzzleDigest(puzzleType, data, author, solutionCommitment, maxSolvers);
         uint proofDigest = uint(keccak256(abi.encodePacked(proof)));

         require(proofUsed[proofDigest] == false, "Proof has already been used");
        
        // Get puzzle data from storage
        Puzzle storage puzzle = puzzles[puzzleDigest];
        
        // Check the puzzleDigest
        require(puzzle.puzzleDigest == puzzleDigest, "Puzzle digest does not match");

        // Check if puzzle has been solved by the caller
        (uint solverDigest, bool solved) = checkIfSolverHasSolved(puzzleDigest, m_s);
        require( solved == false, "Solver has already solved this puzzle");

        // Check that the puzzle is still available to solved
        require(puzzle.numSolvers < maxSolvers, "Maximum number of solvers reached");

        // Verify the proof
        // require(PuzzleLib.verifyProof( solutionCommitment, verificationKey, proof ), "Proof verification failed"); 
        require(verify_signature(m_s, proof, solutionCommitment), "Invalid signature");
        // Emit an event to notify the puzzle has been solved by the caller
        emit PuzzleSolved(puzzleDigest, m_s);

        // Increment the number of solvers
        puzzle.numSolvers++;

        // Flag the proof as already being used
        proofUsed[proofDigest] = true;

        // Set the solver as having solved the puzzle
        puzzleSolved[solverDigest] = true;
    }

    function verify_signature(address solver_message, uint[3] calldata signature, address signer_address) public pure returns (bool){
        bytes32 r = bytes32(signature[0]);
        bytes32 s = bytes32(signature[1]);
        uint8 v = uint8(signature[2]);

        bytes32 prefixedHash = keccak256(abi.encode(solver_message));
        bool result = ecrecover(prefixedHash, v, r, s) == signer_address;
        return result;
    }

    function getPuzzle(uint id) public view returns (Puzzle memory) {
        return puzzles[id];
    }

    function checkIfSolverHasSolved(uint id, address solverAddress) public view returns (uint, bool) {
        uint solverDigest = uint(keccak256(abi.encodePacked(solverAddress, id)));
        return (solverDigest, puzzleSolved[solverDigest]);
    }

    function calculatePuzzleDigest(uint puzzleType, string calldata data, address author, address solutionCommitment, uint256 maxSolvers) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(puzzleType, data, author, solutionCommitment, maxSolvers)));
    }

    // Event to notify when a puzzle with id is created
    event PuzzleCreated(uint256 indexed puzzleDigest, uint256 indexed puzzleType, string data, address indexed author, address solutionCommitment, uint256 maxSolvers);

    // Event to notify the puzzle with id has been solved by the caller (solver)
    event PuzzleSolved(uint indexed puzzleDigest, address indexed solver);
}

