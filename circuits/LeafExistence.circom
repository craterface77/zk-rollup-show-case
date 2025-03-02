pragma circom 2.1.9;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./GetMerkleRoot.circom";

template LeafExistence(l, k) { // l - user state, k - tree height
    signal input root;
    signal input data[l];
    signal input proof_elements[k], proof_positions[k];

    /*
        Use Poseidon to calculate `hash` from user data.
        @inputs (l): amount of inputs
    */
    component hashes = Poseidon(l);
    hashes.inputs <-- data; // send signal to the Poseidon.inputs;

    component merkle_tree = GetMerkleRoot(k);
    merkle_tree.leaf <-- hashes.out; // Poseidon output is a single value
    merkle_tree.proof_elements <-- proof_elements;
    merkle_tree.proof_positions <-- proof_positions;

    assert(root == merkle_tree.root);
}
