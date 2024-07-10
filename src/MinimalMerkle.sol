// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MinimalMerkle {
    bytes32 immutable public i_root;

    error MinimalMerkle__NotInClub();

    constructor(bytes32 _root) {
        i_root = _root;
    }

    function verifyIfInClub(string memory name, bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(name))));

        if (!MerkleProof.verify(proof, i_root, leaf)) {
            revert MinimalMerkle__NotInClub();
        }

        return true;
    }
}
