pragma circom 2.1.2;
include "MerkleRollupTransfer.circom";

component main { public [initial_state_root] } = MerkleRollupTransfer(32);
