/// Minimal compile probe — tests dependency resolution, public visibility,
/// type access, and cross-package compilation against world-contracts.
/// Contains NO business logic. Binary pass/fail integration test only.
module minimal_extension_test::compile_probe;

// === Core module imports ===
use world::gate::{Self, Gate, JumpPermit};
use world::character::{Self, Character};
use world::storage_unit::{Self, StorageUnit};

// === Witness type for extension API probe ===
public struct TestAuth has drop {}

// === Type reference probes ===

/// References public structs from each module to verify type resolution.
/// References public view functions to verify function signature visibility.
/// Does NOT construct objects or execute on-chain.
public fun probe_visibility(
    gate: &Gate,
    character: &Character,
    storage_unit: &StorageUnit,
) {
    // gate module: view function references
    let _online: bool = gate::is_online(gate);
    let _configured: bool = gate::is_extension_configured(gate);
    let _gate_owner: sui::object::ID = gate::owner_cap_id(gate);
    let _linked: option::Option<sui::object::ID> = gate::linked_gate_id(gate);

    // character module: view function references
    let _char_id: sui::object::ID = character::id(character);
    let _tribe: u32 = character::tribe(character);
    let _addr: address = character::character_address(character);

    // storage_unit module: view function references
    let _su_owner: sui::object::ID = storage_unit::owner_cap_id(storage_unit);
}

/// Verifies that the extension witness pattern type-checks.
/// issue_jump_permit<TestAuth> requires: Auth: drop, &Gate x2, &Character,
/// Auth instance, u64, &mut TxContext.
/// We declare the signature to confirm generic type resolution.
public fun probe_extension_type_check(
    source_gate: &Gate,
    destination_gate: &Gate,
    character: &Character,
    ctx: &mut TxContext,
) {
    // Construct the witness — TestAuth has drop, so this is valid.
    let auth = TestAuth {};
    // Type-check issue_jump_permit call with our witness type.
    gate::issue_jump_permit<TestAuth>(
        source_gate,
        destination_gate,
        character,
        auth,
        0u64, // expires_at_timestamp_ms (dummy value, never executed)
        ctx,
    );
}

/// Verifies JumpPermit struct is accessible as a type.
/// Does NOT construct one (only admin/extension can).
public fun probe_jump_permit_type(_permit: &JumpPermit) {
    // Type reference only — confirms JumpPermit is public.
}
