/// ZK Gate — Standalone Groth16 Membership Verification Module
/// ===========================================================
/// Extracted from the zk_gatepass_validation PoC into a clean,
/// production-ready module for GateControl integration.
///
/// Architecture:
///   1. ZKGateConfig (shared object) stores the verification key for a circuit
///   2. verify_membership() takes a proof + public inputs and verifies on-chain
///   3. On success, produces a ZKAuth witness compatible with gate::issue_jump_permit<Auth: drop>
///   4. Full composition test available via test_membership_composition()
///
/// Circuit: Merkle membership proof (depth 10, Poseidon(2), BN254)
///   - Public input: root (Merkle tree root hash)
///   - Private inputs: leaf, pathElements[10], pathIndices[10]
///   - Constraints: 2,430
///
/// Sandbox validation — pre-hackathon devnet testing only.
module zk_gate::zk_gate;

use sui::groth16;
use sui::event;

// ============================================================
// Error codes
// ============================================================
const EProofVerificationFailed: u64 = 1000;
const EInvalidPublicInputsLength: u64 = 1001;

// ============================================================
// Auth witness — drop constraint satisfies gate extension pattern
// ============================================================
/// Single-use authentication token created after successful ZK proof verification.
/// Compatible with gate::issue_jump_permit<Auth: drop>() pattern.
public struct ZKAuth has drop {
    /// The verified Merkle root — downstream can check this matches expected root
    verified_root_bytes: vector<u8>,
}

// ============================================================
// Shared config holding the verification key
// ============================================================
/// On-chain object storing the VK for the membership circuit.
/// Created once by the gate owner, then shared for all verifications.
public struct ZKGateConfig has key, store {
    id: UID,
    /// Serialized VK bytes (arkworks compressed BN254 format)
    vk_bytes: vector<u8>,
    /// Expected number of public inputs (1 for membership circuit)
    expected_public_inputs: u8,
    /// Description for debugging
    circuit_name: vector<u8>,
}

// ============================================================
// Events
// ============================================================
public struct ZKVerificationResult has copy, drop {
    is_valid: bool,
    circuit_name: vector<u8>,
}

public struct ZKAuthIssued has copy, drop {
    root_bytes_len: u64,
}

public struct AuthConsumed has copy, drop {
    message: vector<u8>,
}

public struct CompositionResult has copy, drop {
    zk_verified: bool,
    auth_consumed: bool,
}

// ============================================================
// Config management
// ============================================================

/// Create a new ZKGateConfig with a verification key.
/// The config is shared so all players can read the VK.
entry fun create_config(
    vk_bytes: vector<u8>,
    expected_public_inputs: u8,
    circuit_name: vector<u8>,
    ctx: &mut TxContext,
) {
    let config = ZKGateConfig {
        id: object::new(ctx),
        vk_bytes,
        expected_public_inputs,
        circuit_name,
    };
    transfer::public_share_object(config);
}

// ============================================================
// Core verification — produces ZKAuth witness on success
// ============================================================

/// Verify a Groth16 proof against the stored VK and create an auth witness.
/// The ZKAuth can then be passed to gate::issue_jump_permit<ZKAuth>().
///
/// Returns ZKAuth on success, aborts on failure.
public fun verify_membership(
    config: &ZKGateConfig,
    proof_points_bytes: vector<u8>,
    public_inputs_bytes: vector<u8>,
): ZKAuth {
    // Validate public inputs length (each input is 32 bytes)
    let expected_bytes = (config.expected_public_inputs as u64) * 32;
    assert!(public_inputs_bytes.length() == expected_bytes, EInvalidPublicInputsLength);

    // Verify the Groth16 proof
    let curve = groth16::bn254();
    let pvk = groth16::prepare_verifying_key(&curve, &config.vk_bytes);
    let proof = groth16::proof_points_from_bytes(proof_points_bytes);
    let public_inputs = groth16::public_proof_inputs_from_bytes(public_inputs_bytes);
    let is_valid = groth16::verify_groth16_proof(&curve, &pvk, &public_inputs, &proof);

    assert!(is_valid, EProofVerificationFailed);

    event::emit(ZKVerificationResult {
        is_valid: true,
        circuit_name: config.circuit_name,
    });

    // Create auth witness
    let auth = ZKAuth {
        verified_root_bytes: public_inputs_bytes,
    };
    event::emit(ZKAuthIssued {
        root_bytes_len: public_inputs_bytes.length(),
    });

    auth
}

// ============================================================
// Entry points for devnet testing
// ============================================================

/// Test entry: verify proof and emit result (no auth consumption)
entry fun verify_proof(
    config: &ZKGateConfig,
    proof_points_bytes: vector<u8>,
    public_inputs_bytes: vector<u8>,
    _ctx: &mut TxContext,
) {
    let auth = verify_membership(config, proof_points_bytes, public_inputs_bytes);
    // Auth is dropped here (has drop ability) — in production, pass to gate
    let ZKAuth { verified_root_bytes: _ } = auth;
}

/// Test entry: verify proof and pass auth to gate mock
entry fun verify_and_pass_to_gate(
    config: &ZKGateConfig,
    proof_points_bytes: vector<u8>,
    public_inputs_bytes: vector<u8>,
    _ctx: &mut TxContext,
) {
    let auth = verify_membership(config, proof_points_bytes, public_inputs_bytes);

    // Simulate gate consumption
    mock_consume_auth(auth);

    event::emit(CompositionResult {
        zk_verified: true,
        auth_consumed: true,
    });
}

// ============================================================
// Gate mock — simulates the real gate extension type constraint
// ============================================================

/// Simulates gate::issue_jump_permit<Auth: drop>
/// The critical constraint is Auth: drop — ZKAuth satisfies this.
fun mock_consume_auth<Auth: drop>(_auth: Auth) {
    event::emit(AuthConsumed { message: b"auth_consumed_by_gate_mock" });
}

// ============================================================
// Hardcoded test: membership circuit proof verification
// ============================================================

/// Full test with hardcoded membership circuit proof
/// Circuit: Merkle membership (depth 10, 2430 constraints, 1 public input)
/// Tree: 5 members, leaf=42 at index 0
entry fun test_membership_hardcoded(_ctx: &mut TxContext) {
    // VK bytes (296 bytes) - membership circuit, 2 IC points
    let vkey_bytes = vector[199u8, 226u8, 83u8, 214u8, 219u8, 176u8, 179u8, 101u8, 177u8, 87u8, 117u8, 174u8, 159u8, 138u8, 160u8, 255u8, 204u8, 28u8, 140u8, 222u8, 11u8, 215u8, 164u8, 232u8, 192u8, 179u8, 118u8, 176u8, 217u8, 41u8, 82u8, 164u8, 68u8, 210u8, 97u8, 94u8, 189u8, 162u8, 51u8, 225u8, 65u8, 244u8, 202u8, 10u8, 18u8, 112u8, 225u8, 38u8, 150u8, 128u8, 178u8, 5u8, 7u8, 213u8, 95u8, 104u8, 114u8, 84u8, 10u8, 246u8, 193u8, 188u8, 36u8, 36u8, 219u8, 161u8, 41u8, 138u8, 151u8, 39u8, 255u8, 57u8, 43u8, 111u8, 127u8, 72u8, 179u8, 232u8, 142u8, 32u8, 207u8, 146u8, 91u8, 112u8, 36u8, 190u8, 153u8, 146u8, 211u8, 187u8, 250u8, 232u8, 130u8, 10u8, 9u8, 7u8, 237u8, 246u8, 146u8, 217u8, 92u8, 189u8, 222u8, 70u8, 221u8, 218u8, 94u8, 247u8, 212u8, 34u8, 67u8, 103u8, 121u8, 68u8, 92u8, 94u8, 102u8, 0u8, 106u8, 66u8, 118u8, 30u8, 31u8, 18u8, 239u8, 222u8, 0u8, 24u8, 194u8, 18u8, 243u8, 174u8, 183u8, 133u8, 228u8, 151u8, 18u8, 231u8, 169u8, 53u8, 51u8, 73u8, 170u8, 241u8, 37u8, 93u8, 251u8, 49u8, 183u8, 191u8, 96u8, 114u8, 58u8, 72u8, 13u8, 146u8, 147u8, 147u8, 142u8, 25u8, 22u8, 149u8, 91u8, 104u8, 71u8, 224u8, 106u8, 109u8, 128u8, 19u8, 216u8, 94u8, 27u8, 235u8, 227u8, 56u8, 162u8, 20u8, 3u8, 111u8, 172u8, 73u8, 58u8, 150u8, 217u8, 139u8, 173u8, 199u8, 24u8, 100u8, 23u8, 31u8, 156u8, 168u8, 194u8, 29u8, 32u8, 97u8, 217u8, 100u8, 16u8, 163u8, 8u8, 224u8, 150u8, 230u8, 159u8, 29u8, 30u8, 143u8, 136u8, 227u8, 249u8, 19u8, 75u8, 150u8, 106u8, 110u8, 81u8, 197u8, 201u8, 38u8, 191u8, 162u8, 2u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 5u8, 95u8, 18u8, 100u8, 148u8, 70u8, 35u8, 166u8, 239u8, 143u8, 131u8, 81u8, 120u8, 226u8, 200u8, 24u8, 84u8, 178u8, 81u8, 69u8, 47u8, 59u8, 210u8, 211u8, 239u8, 19u8, 93u8, 129u8, 76u8, 115u8, 160u8, 136u8, 245u8, 129u8, 102u8, 165u8, 176u8, 27u8, 40u8, 28u8, 101u8, 182u8, 126u8, 189u8, 154u8, 20u8, 0u8, 66u8, 159u8, 172u8, 247u8, 104u8, 211u8, 80u8, 73u8, 170u8, 79u8, 28u8, 57u8, 144u8, 96u8, 16u8, 109u8, 156u8];

    // Proof (128 bytes) - valid membership proof for leaf=42 at index 0
    let proof_points_bytes = vector[14u8, 8u8, 81u8, 178u8, 206u8, 29u8, 10u8, 35u8, 85u8, 29u8, 23u8, 77u8, 173u8, 75u8, 14u8, 37u8, 38u8, 162u8, 45u8, 207u8, 149u8, 73u8, 44u8, 171u8, 223u8, 33u8, 146u8, 90u8, 76u8, 70u8, 200u8, 144u8, 20u8, 135u8, 179u8, 52u8, 167u8, 90u8, 182u8, 207u8, 139u8, 252u8, 251u8, 118u8, 100u8, 104u8, 143u8, 54u8, 102u8, 42u8, 33u8, 194u8, 80u8, 90u8, 222u8, 116u8, 7u8, 12u8, 212u8, 28u8, 251u8, 130u8, 17u8, 21u8, 241u8, 79u8, 233u8, 144u8, 156u8, 176u8, 60u8, 153u8, 50u8, 97u8, 185u8, 224u8, 48u8, 30u8, 151u8, 124u8, 141u8, 245u8, 76u8, 198u8, 211u8, 248u8, 241u8, 18u8, 149u8, 44u8, 207u8, 254u8, 169u8, 88u8, 228u8, 166u8, 45u8, 64u8, 54u8, 90u8, 66u8, 28u8, 133u8, 223u8, 255u8, 71u8, 16u8, 177u8, 62u8, 31u8, 77u8, 208u8, 75u8, 211u8, 55u8, 161u8, 226u8, 63u8, 227u8, 220u8, 236u8, 148u8, 46u8, 61u8, 223u8, 193u8, 8u8, 8u8];

    // Public inputs (32 bytes) - Merkle root
    let public_inputs_bytes = vector[127u8, 75u8, 136u8, 116u8, 73u8, 243u8, 127u8, 136u8, 75u8, 164u8, 185u8, 36u8, 245u8, 92u8, 100u8, 166u8, 252u8, 200u8, 63u8, 99u8, 44u8, 145u8, 144u8, 103u8, 194u8, 14u8, 24u8, 13u8, 186u8, 190u8, 19u8, 33u8];

    // Verify
    let curve = groth16::bn254();
    let pvk = groth16::prepare_verifying_key(&curve, &vkey_bytes);
    let proof = groth16::proof_points_from_bytes(proof_points_bytes);
    let public_inputs = groth16::public_proof_inputs_from_bytes(public_inputs_bytes);
    let is_valid = groth16::verify_groth16_proof(&curve, &pvk, &public_inputs, &proof);

    assert!(is_valid, EProofVerificationFailed);

    // Create and consume auth witness via gate mock
    let auth = ZKAuth {
        verified_root_bytes: public_inputs_bytes,
    };
    event::emit(ZKAuthIssued { root_bytes_len: 32 });
    mock_consume_auth(auth);

    event::emit(CompositionResult {
        zk_verified: true,
        auth_consumed: true,
    });
}

/// Negative test: valid proof with wrong public inputs should fail verification
entry fun test_membership_invalid(_ctx: &mut TxContext) {
    // Same VK (296 bytes)
    let vkey_bytes = vector[199u8, 226u8, 83u8, 214u8, 219u8, 176u8, 179u8, 101u8, 177u8, 87u8, 117u8, 174u8, 159u8, 138u8, 160u8, 255u8, 204u8, 28u8, 140u8, 222u8, 11u8, 215u8, 164u8, 232u8, 192u8, 179u8, 118u8, 176u8, 217u8, 41u8, 82u8, 164u8, 68u8, 210u8, 97u8, 94u8, 189u8, 162u8, 51u8, 225u8, 65u8, 244u8, 202u8, 10u8, 18u8, 112u8, 225u8, 38u8, 150u8, 128u8, 178u8, 5u8, 7u8, 213u8, 95u8, 104u8, 114u8, 84u8, 10u8, 246u8, 193u8, 188u8, 36u8, 36u8, 219u8, 161u8, 41u8, 138u8, 151u8, 39u8, 255u8, 57u8, 43u8, 111u8, 127u8, 72u8, 179u8, 232u8, 142u8, 32u8, 207u8, 146u8, 91u8, 112u8, 36u8, 190u8, 153u8, 146u8, 211u8, 187u8, 250u8, 232u8, 130u8, 10u8, 9u8, 7u8, 237u8, 246u8, 146u8, 217u8, 92u8, 189u8, 222u8, 70u8, 221u8, 218u8, 94u8, 247u8, 212u8, 34u8, 67u8, 103u8, 121u8, 68u8, 92u8, 94u8, 102u8, 0u8, 106u8, 66u8, 118u8, 30u8, 31u8, 18u8, 239u8, 222u8, 0u8, 24u8, 194u8, 18u8, 243u8, 174u8, 183u8, 133u8, 228u8, 151u8, 18u8, 231u8, 169u8, 53u8, 51u8, 73u8, 170u8, 241u8, 37u8, 93u8, 251u8, 49u8, 183u8, 191u8, 96u8, 114u8, 58u8, 72u8, 13u8, 146u8, 147u8, 147u8, 142u8, 25u8, 22u8, 149u8, 91u8, 104u8, 71u8, 224u8, 106u8, 109u8, 128u8, 19u8, 216u8, 94u8, 27u8, 235u8, 227u8, 56u8, 162u8, 20u8, 3u8, 111u8, 172u8, 73u8, 58u8, 150u8, 217u8, 139u8, 173u8, 199u8, 24u8, 100u8, 23u8, 31u8, 156u8, 168u8, 194u8, 29u8, 32u8, 97u8, 217u8, 100u8, 16u8, 163u8, 8u8, 224u8, 150u8, 230u8, 159u8, 29u8, 30u8, 143u8, 136u8, 227u8, 249u8, 19u8, 75u8, 150u8, 106u8, 110u8, 81u8, 197u8, 201u8, 38u8, 191u8, 162u8, 2u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 5u8, 95u8, 18u8, 100u8, 148u8, 70u8, 35u8, 166u8, 239u8, 143u8, 131u8, 81u8, 120u8, 226u8, 200u8, 24u8, 84u8, 178u8, 81u8, 69u8, 47u8, 59u8, 210u8, 211u8, 239u8, 19u8, 93u8, 129u8, 76u8, 115u8, 160u8, 136u8, 245u8, 129u8, 102u8, 165u8, 176u8, 27u8, 40u8, 28u8, 101u8, 182u8, 126u8, 189u8, 154u8, 20u8, 0u8, 66u8, 159u8, 172u8, 247u8, 104u8, 211u8, 80u8, 73u8, 170u8, 79u8, 28u8, 57u8, 144u8, 96u8, 16u8, 109u8, 156u8];

    // Same valid proof bytes
    let proof_points_bytes = vector[14u8, 8u8, 81u8, 178u8, 206u8, 29u8, 10u8, 35u8, 85u8, 29u8, 23u8, 77u8, 173u8, 75u8, 14u8, 37u8, 38u8, 162u8, 45u8, 207u8, 149u8, 73u8, 44u8, 171u8, 223u8, 33u8, 146u8, 90u8, 76u8, 70u8, 200u8, 144u8, 20u8, 135u8, 179u8, 52u8, 167u8, 90u8, 182u8, 207u8, 139u8, 252u8, 251u8, 118u8, 100u8, 104u8, 143u8, 54u8, 102u8, 42u8, 33u8, 194u8, 80u8, 90u8, 222u8, 116u8, 7u8, 12u8, 212u8, 28u8, 251u8, 130u8, 17u8, 21u8, 241u8, 79u8, 233u8, 144u8, 156u8, 176u8, 60u8, 153u8, 50u8, 97u8, 185u8, 224u8, 48u8, 30u8, 151u8, 124u8, 141u8, 245u8, 76u8, 198u8, 211u8, 248u8, 241u8, 18u8, 149u8, 44u8, 207u8, 254u8, 169u8, 88u8, 228u8, 166u8, 45u8, 64u8, 54u8, 90u8, 66u8, 28u8, 133u8, 223u8, 255u8, 71u8, 16u8, 177u8, 62u8, 31u8, 77u8, 208u8, 75u8, 211u8, 55u8, 161u8, 226u8, 63u8, 227u8, 220u8, 236u8, 148u8, 46u8, 61u8, 223u8, 193u8, 8u8, 8u8];

    // WRONG public inputs — different root (first byte changed from 127 to 128)
    let public_inputs_bytes = vector[128u8, 75u8, 136u8, 116u8, 73u8, 243u8, 127u8, 136u8, 75u8, 164u8, 185u8, 36u8, 245u8, 92u8, 100u8, 166u8, 252u8, 200u8, 63u8, 99u8, 44u8, 145u8, 144u8, 103u8, 194u8, 14u8, 24u8, 13u8, 186u8, 190u8, 19u8, 33u8];

    let curve = groth16::bn254();
    let pvk = groth16::prepare_verifying_key(&curve, &vkey_bytes);
    let proof = groth16::proof_points_from_bytes(proof_points_bytes);
    let public_inputs = groth16::public_proof_inputs_from_bytes(public_inputs_bytes);
    let is_valid = groth16::verify_groth16_proof(&curve, &pvk, &public_inputs, &proof);

    // Should be false — proof was for a different root
    assert!(!is_valid, 1002);

    event::emit(ZKVerificationResult {
        is_valid: false,
        circuit_name: b"membership_invalid_test",
    });
}
