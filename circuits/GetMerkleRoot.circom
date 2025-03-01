pragma circom 2.2.0;

template GetMerkleRoot(k) {
    signal input leaf;
    signal input proof_elements[k], proof_positions[k];

    signal left, right;
    signal current <== leaf;

    signal root; // returns root hash

    component hashes[k];

    for (var i = 0; i < k; i++) {
        /*
        Example:
            current=42
            proof_elements[i]=100

            @if proof_positions[i]=0:

            left= 0 * 100 + (1 - 0) * 42 = 0 + 1 * 42 = 42
            right= 0 * 42 + (1 - 0) * 100 = 0 + 1 * 100 = 100

            @if proof_positions[i]=1:

            left= 1 * 100 + (1 - 1) * 42 = 1 * 100 + 0 = 100
            right= 1 * 42 + (1 - 1) * 100 = 1 * 42 + 0 = 42
        */
        left <-- proof_positions[i] * proof_elements[i] + (1 - proof_positions[i]) * current;
        right <-- proof_positions[i] * current + (1 - proof_positions[i]) * proof_elements[i];

        hashes[i] = MiMCSponge(2, 220, 1);
        hashes[i].ins[0] <== left;
        hashes[i].ins[1] <== right;
        hashes[i].k <== 1;

        current <== hashes[i].outs[0];
    }

    root <== current;
}
