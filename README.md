# Merkle Rollup Transfer (Circom)

## Overview

This project implements a **Zero-Knowledge (ZK) Merkle Rollup Transfer** using **Circom**, allowing secure and efficient off-chain transaction validation with Merkle trees. It ensures that funds are correctly transferred between users without revealing sensitive information on-chain.

The circuits verify:

1. **Sender and receiver existence** in a Merkle tree.
2. **Sender's balance is sufficient** before the transaction.
3. **Correct transaction signature** using EdDSA.
4. **Updated balances** and new Merkle root after the transaction.
5. **New Merkle root correctness**, ensuring consistency.

## ⚙️ How It Works

The project includes three main Circom circuits:

1. **`MerkleRollupTransfer.circom`** - Handles the transfer logic.
2. **`LeafExistence.circom`** - Checks if an account exists in the Merkle tree.
3. **`GetMerkleRoot.circom`** - Computes a Merkle tree root after state updates.

## File Descriptions

### MerkleRollupTransfer.circom

**Purpose:** Verifies a transaction and updates the Merkle root.

**Steps:**

1. **Verify sender account exists** in the current Merkle root (`initial_state_root`).
2. **Hash the transaction** (sender, receiver, amount) using MiMCSponge.
3. **Verify sender's signature** using EdDSA.
4. **Ensure sender has sufficient balance** before proceeding.
5. **Update sender's balance** (`sender_balance - amount`).
6. **Compute the new Merkle root** after sender update.
7. **Verify receiver's existence** in the updated Merkle tree.
8. **Update receiver's balance** (`receiver_balance + amount`).
9. **Compute the final Merkle root** after receiver update.
10. **Return the new Merkle root** (`new_root`).

### LeafExistence.circom

**Purpose:** Verifies that a given leaf (account) exists in a Merkle tree.

**Steps:**

1. **Hashes the account data** (public key, balance) using MiMCSponge.
2. **Calculates the Merkle root** using `GetMerkleRoot`.
3. **Compares the computed root to the expected root**.
4. **Ensures validity of the proof** (`assert(root == computed_root)`).

### GetMerkleRoot.circom

**Purpose:** Computes a Merkle root from a leaf node and a Merkle proof.

**Steps:**

1. **Iterates through Merkle proof levels**, updating `left` and `right` based on `proof_positions[i]`.
2. **Uses MiMCSponge to compute the parent hash**.
3. **Final computed value is the Merkle root**.

## Example Transaction Flow

- **Sender:** Public Key (Px, Py), balance `100`
- **Receiver:** Public Key (Px, Py), balance `50`
- **Transaction:** `amount = 30`

The circuit checks:

1. Sender is in Merkle tree.
2. Sender has at least 30.
3. Transaction is signed.
4. Merkle root updates correctly.
5. Receiver’s balance updates correctly.
6. New Merkle root is valid.

Final result:

- **Sender's new balance:** `70`
- **Receiver's new balance:** `80`
- **New Merkle Root is computed**

## Use Cases

- **zk-Rollups**: Batch multiple transactions to reduce gas costs.
- **Private Payments**: Users can transact without revealing balances.
- **Layer 2 Scaling**: Off-chain computation, minimal on-chain footprint.
- **Blockchain Optimizations**: Efficient storage using Merkle roots.
