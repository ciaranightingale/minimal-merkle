// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Merkle} from "murky/src/Merkle.sol";
import {ScriptHelper} from "murky/script/common/ScriptHelper.sol";

// Merkle proof generator script
// To use:
// 1. Run `forge script script/GenerateInput.s.sol` to generate the input file
// 2. Run `forge script script/Merkle.s.sol`
// 3. The output file will be generated in /script/target/output.json

/** 
 * @title MakeMerkle
 * @author Ciara Nightingale
 * @author Cyfrin
 *
 * Original Work by:
 * @author kootsZhin
 * @notice https://github.com/dmfxyz/murky
 */

contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string; // enables us to use the json cheatcodes for strings

    Merkle private m = new Merkle(); // instance of the merkle contract from Murky to do shit 

    string private inputPath = "/script/target/input.json";
    string private outputPath = "/script/target/output.json";

    string private elements = vm.readFile(string.concat(vm.projectRoot(), inputPath)); // get the absolute path 
    string[] private types = elements.readStringArray(".types"); // gets the merkle tree leaf types from json using forge standard lib cheatcode 
    uint256 private count = elements.readUint(".count"); // get the number of leaf nodes

    // make three arrays the same size as the number of leaf nodes
    bytes32[] private leafs = new bytes32[](count);  

    string[] private inputs = new string[](count);
    string[] private outputs = new string[](count);

    string private output;

    /// @dev Returns the JSON path of the input file
    // output file output ".values.some-address.some-amount"
    function getValuesByIndex(uint256 i, uint256 j) internal pure returns (string memory) {
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    } 

    /// @dev Generate the JSON entries for the output file
    function generateJsonEntries(string memory _inputs, string memory _proof, string memory _root, string memory _leaf)
        internal
        pure
        returns (string memory)
    {
        string memory result = string.concat(
            "{",
            "\"inputs\":",
            _inputs,
            ",",
            "\"proof\":",
            _proof,
            ",",
            "\"root\":\"",
            _root,
            "\",",
            "\"leaf\":\"",
            _leaf,
            "\"",
            "}"
        );

        return result;
    }

    /// @dev Read the input file and generate the Merkle proof, then write the output file
    function run() public {
        console.log("Generating Merkle Proof for %s", inputPath);

        for (uint256 i = 0; i < count; ++i) {
            string[] memory input = new string[](types.length); // stringified data
            // this will only work if there are only strings in the leaf nodes!!
            for (uint256 j = 0; j < types.length; ++j) {
                if (compareStrings(types[j], "string")) {
                    string memory value = elements.readString(getValuesByIndex(i, j));
                    input[j] = value;
                }
            }
            // Create the hash for the merkle tree leaf node
            // abi encode the input
            // Helper from Murky (ltrim64) Returns the bytes with the first 64 bytes removed 
            // ltrim64 removes the offset and length from the encoded bytes. There is an offset because the array
            // is declared in memory 
            // hash the input
            // bytes.concat turns from bytes32 to bytes 
            // hash again because preimage attack
            leafs[i] = keccak256(bytes.concat(keccak256(ltrim64(abi.encode(input)))));
            // Converts a string array into a JSON array string.
            // store the corresponding values/inputs for each leaf node
            inputs[i] = stringArrayToString(input);
        }

        for (uint256 i = 0; i < count; ++i) {
            // get proof gets the nodes needed for the proof & strigify (from helper lib)
            string memory proof = bytes32ArrayToString(m.getProof(leafs, i));
            // get the root hash and stringify
            string memory root = vm.toString(m.getRoot(leafs));
            // get the specific leaf working on
            string memory leaf = vm.toString(leafs[i]);
            // get the singified input (address, amount)
            string memory input = inputs[i];

            // generate the Json output file (tree dump)
            outputs[i] = generateJsonEntries(input, proof, root, leaf);
        }

        // stringify the array of strings to a single string
        output = stringArrayToArrayString(outputs);
        // write to the output file the stringified output json tree dumpus 
        vm.writeFile(string.concat(vm.projectRoot(), outputPath), output);

        console.log("DONE: The output is found at %s", outputPath);
    }
}
