//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library PuzzleLib {
    struct Puzzle {
        uint puzzleDigest;
        uint numSolvers;
    }

    function verifyProof( uint[2] memory solutionCommitment, uint[2] memory g, uint[3] memory proof) internal view returns (bool) {

        // Initialize variables
        uint[2] memory a;
        uint z;

        // Extract A and z from proof
        a[0] = proof[0];
        a[1] = proof[1];
        z = proof[2];

        // Compute Fiat-Shamir challenge, e
        uint e = fiatShamirChallenge(g, solutionCommitment, a);

         // lhs = a + [e]solutionCommitment
        solutionCommitment = callBn256ScalarMul(solutionCommitment[0], solutionCommitment[1], e);
        uint[2] memory lhs = callBn256Add(solutionCommitment[0], solutionCommitment[1], a[0], a[1]);

        //rhs = [z]g
        uint[2] memory rhs = callBn256ScalarMul(g[0], g[1], z);
        return (lhs[0] == rhs[0] && lhs[1] == rhs[1]);
    }

    // compute Fiat-Shamir challenge from  on an array of uints
    function fiatShamirChallenge(uint[2] memory g, uint[2] memory solutionCommitment, uint[2] memory a) public pure returns (uint) {
        return uint(sha256(abi.encode(g, solutionCommitment, a))) & 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
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

