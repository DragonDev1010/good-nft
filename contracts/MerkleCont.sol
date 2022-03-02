// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleCont {
    bytes32 public root;
    bytes32 public leaf;
    bytes public abi_;
    event Test(bool verified);

    function setRoot(bytes32 root_) public {
        root = root_;
    }
    
    function verify(bytes32[] calldata _proof, uint256 level) public returns(bool) {
        leaf = keccak256(abi.encodePacked(msg.sender, level));
        bool veri = MerkleProof.verify(_proof, root, leaf);
        emit Test(veri);
        return MerkleProof.verify(_proof, root, leaf);
    }

    function test(uint256 lvl) public {
        abi_ = abi.encodePacked(msg.sender);
        leaf = keccak256(abi_);
    }
}

// 0xd5e753f24d9e54ed71bad0ce39ebcdac02356d0d0000000000000000000000000000000000000000000000000000000000000001