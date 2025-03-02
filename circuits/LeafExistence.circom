pragma circom 2.1.9;

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "./GetMerkleRoot.circom";

template LeafExistence(l, k) { // l - user state, k - tree hight
    signal input root;
    signal input data[l];
    signal input proof_elements[k], proof_positions[k];

    /*
        Lib for calculating `hash` from user data
        @nInputs (l): amount of inputs
        @nRounds (220): nRounds should be 220 by settings
        @nOutputs (1): last index of `output` array
    */
    component hashes = MiMCSponge(l, 220, 1);
    hashes.ins <-- data; // send signal to the MiMCSponge.ins;
    hashes.k <== 1; // send signal to the MiMCSponge.k;

    component merkle_tree = GetMerkleRoot(k);
    merkle_tree.leaf <-- hashes.outs[0]; // [0] - hash result
    merkle_tree.proof_elements <-- proof_elements;
    merkle_tree.proof_positions <-- proof_positions;

    assert(root == merkle_tree.root);
}
