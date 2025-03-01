pragma circom 2.2.0;

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

include "./LeafExistence.circom";
include "./GetMerkleRoot.circom";


template MerkleRollupTransfer(k) { // k is the depth of accounts tree
    signal input initial_state_root;

    // Sender account info
    signal input sender_pub_key[2], sender_balance;
    signal input sender_proof_elements[k], sender_proof_positions[k];

    // Receiver account info
    signal input receiver_pub_key[2], receiver_balance;
    signal input receiver_proof_elements[k], receiver_proof_positions[k];

    // Transactions info
    signal input amount;
    signal input sig_S, sig_R8x, sig_R8y;

    // Output root
    signal output new_root;

    // Verify sender account exists in `initial_rollup_root`
    component check_sender = LeafExistence(3, k); // 2 elems (sender_pub_key2) + 1 elem (sender_balance) = 3
    check_sender.root <-- initial_state_root;
    check_sender.data[0] <-- sender_pub_key[0];
    check_sender.data[1] <-- sender_pub_key[1];
    check_sender.data[2] <-- sender_balance;
    check_sender.proof_elements <-- sender_proof_elements;
    check_sender.proof_positions <-- sender_proof_positions;

    // Get transaction hash
    component msg_hashes = MiMCSponge(5, 220, 1); // 5 = 2 + 2 public keys + 1 amount
    msg_hashes.ins[0] <-- sender_pub_key[0];
    msg_hashes.ins[1] <-- sender_pub_key[1];
    msg_hashes.ins[2] <-- receiver_pub_key[0];
    msg_hashes.ins[3] <-- receiver_pub_key[1];
    msg_hashes.ins[4] <-- amount;
    msg_hashes.k <== 1;

    // Check that transaction was signed by sender
    component sig_verifier = EdDSAMiMCVerifier();
    sig_verifier.enabled <== 1;
    sig_verifier.Ax <-- sender_pub_key[0];
    sig_verifier.Ay <-- sender_pub_key[1];
    sig_verifier.S <-- sig_S;
    sig_verifier.R8x <-- sig_R8x;
    sig_verifier.R8y <-- sig_R8y;
    sig_verifier.M <-- msg_hashes.outs[0];

    // Check sender balance
    component validate_sender_balance = LessEqThan(252); // 252 - the maximum digit of bytes
    validate_sender_balance.in[0] <-- amount;
    validate_sender_balance.in[1] <-- sender_balance;
    assert(validate_sender_balance.out == 1); // out is eq true;

    // Debit sender account
    component new_sender_leaf_hash = MiMCSponge(3, 220, 1);
    new_sender_leaf_hash.ins[0] <-- sender_pub_key[0];
    new_sender_leaf_hash.ins[1] <-- sender_pub_key[1];
    new_sender_leaf_hash.ins[2] <== sender_balance - amount;
    new_sender_leaf_hash.k <== 1;

    // Compute new root
    component compute_updated_root = GetMerkleRoot(k);
    compute_updated_root.leaf <-- new_sender_leaf_hash.outs[0];
    compute_updated_root.proof_elements <-- sender_proof_elements;
    compute_updated_root.proof_positions <-- sender_proof_positions;

    // Verify receiver account exists in intermediate root
    component check_receiver = LeafExistence(3, k); // 2 elems (sender_pub_keys) + 1 elem (sender_balance) = 3
    check_receiver.root <== compute_updated_root.root;
    check_receiver.data[0] <-- receiver_pub_key[0];
    check_receiver.data[1] <-- receiver_pub_key[1];
    check_receiver.data[2] <-- receiver_balance;
    check_receiver.proof_elements <-- receiver_proof_elements;
    check_receiver.proof_positions <-- receiver_proof_positions;

    // Credit receiver account
    component new_receiver_leaf_hash = MiMCSponge(3, 220, 1);
    new_receiver_leaf_hash.ins[0] <-- receiver_pub_key[0];
    new_receiver_leaf_hash.ins[1] <-- receiver_pub_key[1];
    new_receiver_leaf_hash.ins[2] <== receiver_balance + amount;
    new_receiver_leaf_hash.k <== 1;

    // Compute final root
    component compute_final_root = GetMerkleRoot(k);
    compute_final_root.leaf <-- new_receiver_leaf_hash.outs[0];
    compute_final_root.proof_elements <-- receiver_proof_elements;
    compute_final_root.proof_positions <-- receiver_proof_positions;

    // Return final root
    new_root <== compute_final_root.root;
}
