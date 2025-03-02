pragma circom 2.1.9;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

include "./LeafExistence.circom";
include "./GetMerkleRoot.circom";

template MerkleRollupTransfer(k) { // k is the depth of accounts tree
    signal input initial_state_root;

    // Sender account info
    signal input sender_pub_key[2], sender_balance, sender_nonce;
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
    component check_sender = LeafExistence(4, k); // 2 pub_key + 1 balance + 1 nonce = 4
    check_sender.root <-- initial_state_root;
    check_sender.data[0] <-- sender_pub_key[0];
    check_sender.data[1] <-- sender_pub_key[1];
    check_sender.data[2] <-- sender_balance;
    check_sender.data[3] <-- sender_nonce;
    check_sender.proof_elements <-- sender_proof_elements;
    check_sender.proof_positions <-- sender_proof_positions;

    // Get transaction hash using Poseidon
    component msg_hashes = Poseidon(6);
    msg_hashes.inputs[0] <-- sender_pub_key[0];
    msg_hashes.inputs[1] <-- sender_pub_key[1];
    msg_hashes.inputs[2] <-- receiver_pub_key[0];
    msg_hashes.inputs[3] <-- receiver_pub_key[1];
    msg_hashes.inputs[4] <-- amount;
    msg_hashes.inputs[5] <-- sender_nonce;

    // Check that transaction was signed by sender
    component sig_verifier = EdDSAMiMCVerifier();
    sig_verifier.enabled <== 1;
    sig_verifier.Ax <-- sender_pub_key[0];
    sig_verifier.Ay <-- sender_pub_key[1];
    sig_verifier.S <-- sig_S;
    sig_verifier.R8x <-- sig_R8x;
    sig_verifier.R8y <-- sig_R8y;
    sig_verifier.M <-- msg_hashes.out;

    // Check sender balance
    component validate_sender_balance = LessEqThan(252);
    validate_sender_balance.in[0] <-- amount;
    validate_sender_balance.in[1] <-- sender_balance;
    assert(validate_sender_balance.out == 1);

    // Update sender account (balance - amount, nonce + 1) using Poseidon
    component new_sender_leaf_hash = Poseidon(4);
    new_sender_leaf_hash.inputs[0] <-- sender_pub_key[0];
    new_sender_leaf_hash.inputs[1] <-- sender_pub_key[1];
    new_sender_leaf_hash.inputs[2] <== sender_balance - amount;
    new_sender_leaf_hash.inputs[3] <== sender_nonce + 1;

    // Compute new root
    component compute_updated_root = GetMerkleRoot(k);
    compute_updated_root.leaf <-- new_sender_leaf_hash.out;
    compute_updated_root.proof_elements <-- sender_proof_elements;
    compute_updated_root.proof_positions <-- sender_proof_positions;

    // Verify receiver account exists in intermediate root
    component check_receiver = LeafExistence(3, k);
    check_receiver.root <== compute_updated_root.root;
    check_receiver.data[0] <-- receiver_pub_key[0];
    check_receiver.data[1] <-- receiver_pub_key[1];
    check_receiver.data[2] <-- receiver_balance;
    check_receiver.proof_elements <-- receiver_proof_elements;
    check_receiver.proof_positions <-- receiver_proof_positions;

    // Credit receiver account using Poseidon
    component new_receiver_leaf_hash = Poseidon(3);
    new_receiver_leaf_hash.inputs[0] <-- receiver_pub_key[0];
    new_receiver_leaf_hash.inputs[1] <-- receiver_pub_key[1];
    new_receiver_leaf_hash.inputs[2] <== receiver_balance + amount;

    // Compute final root
    component compute_final_root = GetMerkleRoot(k);
    compute_final_root.leaf <-- new_receiver_leaf_hash.out;
    compute_final_root.proof_elements <-- receiver_proof_elements;
    compute_final_root.proof_positions <-- receiver_proof_positions;

    // Return final root
    new_root <== compute_final_root.root;
}
