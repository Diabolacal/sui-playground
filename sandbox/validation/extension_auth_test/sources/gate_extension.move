/// Gate extension module — validates cross-package Auth witness with world::gate.
///
/// This module exercises the critical claims:
/// - gate::authorize_extension<XAuth> accepts our package's XAuth type
/// - gate::issue_jump_permit<XAuth> accepts our package's XAuth witness instance
///
/// The authorize_gate function is called by the gate owner (via OwnerCap<Gate>).
/// The issue_jump_permit function is the player-facing entry point.
#[allow(unused_use)]
module extension_auth_test::gate_extension;

use extension_auth_test::config::{Self, XAuth, ExtensionConfig};
use sui::clock::Clock;
use world::{
    access::OwnerCap,
    character::Character,
    gate::{Self, Gate},
};

// === Errors ===
#[error(code = 0)]
const ENoAllowConfig: vector<u8> = b"Missing AllowConfig on ExtensionConfig";
#[error(code = 1)]
const EExpiryOverflow: vector<u8> = b"Expiry timestamp overflow";

/// Minimal rule: just an expiry duration for issued permits.
public struct AllowConfig has drop, store {
    expiry_duration_ms: u64,
}

/// DF key for AllowConfig.
public struct AllowConfigKey has copy, drop, store {}

// === Gate Owner Functions ===

/// Authorize this extension on a gate. Called by gate owner.
/// Validates E2E-02: cross-package generic instantiation of authorize_extension.
public fun authorize(
    gate: &mut Gate,
    owner_cap: &OwnerCap<Gate>,
) {
    gate::authorize_extension<XAuth>(gate, owner_cap);
}

// === Player Functions ===

/// Issue a JumpPermit to any character (no filtering — permit-all extension).
/// Validates E2E-03: cross-package issue_jump_permit with our Auth witness.
public fun issue_jump_permit(
    extension_config: &ExtensionConfig,
    source_gate: &Gate,
    destination_gate: &Gate,
    character: &Character,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(extension_config.has_rule<AllowConfigKey>(AllowConfigKey {}), ENoAllowConfig);
    let allow_cfg = extension_config.borrow_rule<AllowConfigKey, AllowConfig>(AllowConfigKey {});

    let expiry_ms = allow_cfg.expiry_duration_ms;
    let ts = clock.timestamp_ms();
    assert!(ts <= (0xFFFFFFFFFFFFFFFFu64 - expiry_ms), EExpiryOverflow);
    let expires_at = ts + expiry_ms;

    gate::issue_jump_permit<XAuth>(
        source_gate,
        destination_gate,
        character,
        config::x_auth(),
        expires_at,
        ctx,
    );
}

// === Admin Functions ===

/// Set the allow-all config rule.
public fun set_allow_config(
    extension_config: &mut ExtensionConfig,
    admin_cap: &config::AdminCap,
    expiry_duration_ms: u64,
) {
    config::set_rule(
        extension_config,
        admin_cap,
        AllowConfigKey {},
        AllowConfig { expiry_duration_ms },
    );
}
