pragma circom 2.1.9;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (s - 1) === 0;

    out[0] <== (in[1] - in[0]) * s + in[0];
    out[1] <== (in[0] - in[1]) * s + in[1];
}

template GetMerkleRoot(k) { // k is depth of tree
    signal input leaf;
    signal input proof_elements[k], proof_positions[k];

    signal output root;

    component selectors[k];
    component hashers[k];

    for(var i = 0; i < k; i++){
        selectors[i] = DualMux();
        selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].outs[0];
        selectors[i].in[1] <== proof_elements[i];
        selectors[i].s <== proof_positions[i];

        hashers[i] = MiMCSponge(2, 220, 1);
        hashers[i].ins[0] <== selectors[i].out[0];
        hashers[i].ins[1] <== selectors[i].out[1];
        hashers[i].k <== 1;
    }

    root <== hashers[k-1].outs[0];
}
