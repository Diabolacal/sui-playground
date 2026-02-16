/// Test B: ZK + Gate Extension composition validation
/// Validates that Groth16 verification can produce an Auth witness
/// compatible with the gate::issue_jump_permit<Auth: drop> pattern
module zk_gatepass_validation::zk_gate_compose;

use sui::groth16;
use sui::event;

// ============================================================
// Auth witness — must satisfy `drop` constraint for gate extension
// ============================================================
/// Single-use authentication token created after successful ZK proof verification.
/// Consumed by the gate extension function (simulated here by mock_consume_auth).
public struct ZKAuth has drop {
    /// Hash of verified public inputs — allows downstream audit
    verified_signal_0: u64,
}

// ============================================================
// Shared config holding the verification key
// ============================================================
/// On-chain object storing the VK for a specific circuit.
/// In production, this would be created once and shared.
public struct ZKGateConfig has key, store {
    id: UID,
    vk_bytes: vector<u8>,
}

// ============================================================
// Events
// ============================================================
public struct ZKAuthIssued has copy, drop {
    signal_0: u64,
}

public struct AuthConsumed has copy, drop {
    message: vector<u8>,
}

public struct CompositionResult has copy, drop {
    zk_verified: bool,
    auth_consumed: bool,
}

// ============================================================
// Gate extension mock — mirrors the real type constraint
// ============================================================
/// Simulates gate::issue_jump_permit<Auth: drop>
/// The critical constraint is Auth: drop — ZKAuth must satisfy this.
fun mock_consume_auth<Auth: drop>(_auth: Auth) {
    // In the real gate, this would create a JumpPermit.
    // Here we just verify the type constraint is satisfied.
    event::emit(AuthConsumed { message: b"auth_consumed_by_gate" });
}

// ============================================================
// Core: verify proof → create ZKAuth → pass to gate mock
// ============================================================

/// Step 1: Create a shared config (call once, then share)
entry fun create_config(vk_bytes: vector<u8>, ctx: &mut TxContext) {
    let config = ZKGateConfig {
        id: object::new(ctx),
        vk_bytes,
    };
    transfer::public_share_object(config);
}

/// Step 2: Full composition test — verify ZK proof then consume auth via gate mock
/// This validates the complete flow in a single PTB:
///   1. Groth16 verify with VK from shared config
///   2. Create ZKAuth witness on success
///   3. Pass ZKAuth to mock_consume_auth<ZKAuth>
entry fun verify_and_pass_to_gate(
    config: &ZKGateConfig,
    proof_points_bytes: vector<u8>,
    public_inputs_bytes: vector<u8>,
    ctx: &mut TxContext,
) {
    // Step 1: Verify Groth16 proof
    let curve = groth16::bn254();
    let pvk = groth16::prepare_verifying_key(&curve, &config.vk_bytes);
    let proof = groth16::proof_points_from_bytes(proof_points_bytes);
    let public_inputs = groth16::public_proof_inputs_from_bytes(public_inputs_bytes);
    let is_valid = groth16::verify_groth16_proof(&curve, &pvk, &public_inputs, &proof);
    assert!(is_valid, 2000); // ZK proof verification failed

    // Step 2: Create ZKAuth witness (only if proof is valid)
    let auth = ZKAuth {
        verified_signal_0: 21, // In production, parse from public_inputs
    };
    event::emit(ZKAuthIssued { signal_0: 21 });

    // Step 3: Pass auth to gate mock (validates Auth: drop constraint)
    mock_consume_auth(auth);

    // Step 4: Emit composition result
    event::emit(CompositionResult {
        zk_verified: true,
        auth_consumed: true,
    });
}

/// Hardcoded composition test — no shared object needed
/// Uses the same proof/VK from Test A
entry fun test_hardcoded_composition(_ctx: &mut TxContext) {
    // VK bytes (328 bytes with IC length prefix)
    let vkey_bytes = vector[245u8, 81u8, 160u8, 87u8, 91u8, 61u8, 2u8, 13u8, 15u8, 62u8, 158u8, 67u8, 99u8, 211u8, 169u8, 127u8, 17u8, 18u8, 8u8, 76u8, 226u8, 175u8, 169u8, 12u8, 191u8, 78u8, 53u8, 79u8, 86u8, 212u8, 136u8, 3u8, 92u8, 36u8, 70u8, 40u8, 78u8, 207u8, 130u8, 44u8, 168u8, 85u8, 15u8, 105u8, 15u8, 162u8, 59u8, 94u8, 106u8, 101u8, 215u8, 34u8, 235u8, 107u8, 41u8, 236u8, 93u8, 222u8, 48u8, 253u8, 222u8, 152u8, 170u8, 22u8, 184u8, 96u8, 216u8, 77u8, 3u8, 126u8, 151u8, 107u8, 210u8, 38u8, 41u8, 210u8, 106u8, 223u8, 107u8, 135u8, 253u8, 99u8, 229u8, 251u8, 122u8, 197u8, 68u8, 5u8, 217u8, 254u8, 251u8, 185u8, 81u8, 3u8, 189u8, 5u8, 237u8, 246u8, 146u8, 217u8, 92u8, 189u8, 222u8, 70u8, 221u8, 218u8, 94u8, 247u8, 212u8, 34u8, 67u8, 103u8, 121u8, 68u8, 92u8, 94u8, 102u8, 0u8, 106u8, 66u8, 118u8, 30u8, 31u8, 18u8, 239u8, 222u8, 0u8, 24u8, 194u8, 18u8, 243u8, 174u8, 183u8, 133u8, 228u8, 151u8, 18u8, 231u8, 169u8, 53u8, 51u8, 73u8, 170u8, 241u8, 37u8, 93u8, 251u8, 49u8, 183u8, 191u8, 96u8, 114u8, 58u8, 72u8, 13u8, 146u8, 147u8, 147u8, 142u8, 25u8, 12u8, 38u8, 197u8, 91u8, 192u8, 37u8, 7u8, 123u8, 199u8, 146u8, 159u8, 156u8, 232u8, 87u8, 95u8, 93u8, 206u8, 76u8, 194u8, 204u8, 60u8, 235u8, 71u8, 246u8, 60u8, 127u8, 30u8, 148u8, 87u8, 97u8, 14u8, 46u8, 93u8, 21u8, 241u8, 109u8, 10u8, 2u8, 119u8, 85u8, 20u8, 223u8, 144u8, 235u8, 27u8, 111u8, 104u8, 179u8, 116u8, 184u8, 66u8, 141u8, 11u8, 249u8, 101u8, 202u8, 52u8, 242u8, 252u8, 244u8, 46u8, 228u8, 17u8, 154u8, 3u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 252u8, 90u8, 11u8, 192u8, 147u8, 229u8, 210u8, 226u8, 26u8, 45u8, 130u8, 67u8, 185u8, 189u8, 94u8, 240u8, 145u8, 245u8, 224u8, 91u8, 143u8, 198u8, 68u8, 46u8, 79u8, 187u8, 252u8, 3u8, 240u8, 78u8, 251u8, 33u8, 189u8, 50u8, 218u8, 93u8, 142u8, 253u8, 102u8, 152u8, 159u8, 232u8, 15u8, 168u8, 219u8, 13u8, 19u8, 203u8, 196u8, 106u8, 173u8, 225u8, 167u8, 200u8, 39u8, 43u8, 28u8, 154u8, 158u8, 2u8, 110u8, 123u8, 190u8, 131u8, 8u8, 160u8, 91u8, 115u8, 206u8, 255u8, 119u8, 143u8, 61u8, 174u8, 135u8, 179u8, 170u8, 0u8, 138u8, 89u8, 17u8, 25u8, 165u8, 144u8, 149u8, 228u8, 34u8, 153u8, 23u8, 196u8, 144u8, 138u8, 152u8, 105u8, 8u8, 0u8];

    // Proof points (128 bytes)
    let proof_points_bytes = vector[208u8, 46u8, 222u8, 51u8, 150u8, 189u8, 190u8, 68u8, 204u8, 185u8, 208u8, 251u8, 214u8, 185u8, 38u8, 234u8, 228u8, 221u8, 5u8, 52u8, 173u8, 242u8, 210u8, 44u8, 148u8, 147u8, 12u8, 195u8, 115u8, 188u8, 214u8, 47u8, 177u8, 241u8, 36u8, 16u8, 123u8, 180u8, 80u8, 11u8, 186u8, 56u8, 166u8, 195u8, 72u8, 126u8, 226u8, 43u8, 228u8, 170u8, 30u8, 82u8, 255u8, 161u8, 19u8, 220u8, 23u8, 31u8, 56u8, 246u8, 25u8, 230u8, 238u8, 5u8, 69u8, 153u8, 66u8, 88u8, 39u8, 215u8, 117u8, 248u8, 23u8, 44u8, 73u8, 120u8, 220u8, 95u8, 186u8, 241u8, 66u8, 14u8, 91u8, 151u8, 235u8, 62u8, 184u8, 48u8, 75u8, 102u8, 79u8, 232u8, 249u8, 176u8, 155u8, 22u8, 154u8, 86u8, 57u8, 53u8, 126u8, 92u8, 139u8, 171u8, 35u8, 253u8, 49u8, 76u8, 103u8, 68u8, 1u8, 44u8, 39u8, 221u8, 108u8, 85u8, 15u8, 191u8, 216u8, 48u8, 119u8, 238u8, 29u8, 54u8, 30u8, 170u8, 232u8, 6u8];

    // Public inputs (64 bytes, little-endian) - [21, 7]
    let public_inputs_bytes = vector[21u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 7u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8, 0u8];

    // Step 1: Verify
    let curve = groth16::bn254();
    let pvk = groth16::prepare_verifying_key(&curve, &vkey_bytes);
    let proof = groth16::proof_points_from_bytes(proof_points_bytes);
    let public_inputs = groth16::public_proof_inputs_from_bytes(public_inputs_bytes);
    let is_valid = groth16::verify_groth16_proof(&curve, &pvk, &public_inputs, &proof);
    assert!(is_valid, 2000);

    // Step 2: Create auth witness
    let auth = ZKAuth { verified_signal_0: 21 };
    event::emit(ZKAuthIssued { signal_0: 21 });

    // Step 3: Pass to gate mock (validates Auth: drop constraint)
    mock_consume_auth(auth);

    // Step 4: Emit result
    event::emit(CompositionResult {
        zk_verified: true,
        auth_consumed: true,
    });
}
