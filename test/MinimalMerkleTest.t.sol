// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MinimalMerkle} from "../src/MinimalMerkle.sol";
import {Test} from "forge-std/Test.sol";

contract MinimalMerkleTest is Test {

    bytes32 root = 0x6e10420ea854c1d5c4c2e7ecf3e1f79e6963f43f924a009f5bf6d45da592d1cf;
    MinimalMerkle merkle = new MinimalMerkle(root);

    function testIsPartOfVipClub() public view returns (bool) {
        bytes32 proof1 = 0xfcedff7fd13c323a60b257d4553f350831c1694fd3a953ed9bb5af1abd127fb8;
        bytes32 proof2 = 0x7c1a4a44f893dd1de1745304d1b2a6413f937d10c458bdd45ede7c53b87e3a0e;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof1;
        proof[1] = proof2;

        vm.assertTrue(merkle.verifyIfInClub("Ciara", proof));
    }

    function testNotPartOfVipClub() public returns (bool) {
        bytes32 proof1 = 0xfcedff7fd13c323a60b257d4553f350831c1694fd3a953ed9bb5af1abd127fb8;
        bytes32 proof2 = 0x7c1a4a44f893dd1de1745304d1b2a6413f937d10c458bdd45ede7c53b87e3a0e;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof1;
        proof[1] = proof2;

        vm.expectRevert(MinimalMerkle.MinimalMerkle__NotInClub.selector);
        merkle.verifyIfInClub("Sam", proof);
    }
}