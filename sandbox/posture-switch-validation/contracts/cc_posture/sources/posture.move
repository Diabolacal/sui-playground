/// CivilizationControl Posture Presets — on-chain configuration.
///
/// Manages two posture modes:
///   BUSINESS (0) — broad access + toll (toll is stubbed), turrets offline
///   DEFENSE  (1) — tribe-only access, turrets online
///
/// DFs on shared ExtensionConfig:
///   PostureConfigKey → PostureConfig { mode }
///   TribeConfigKey   → TribeConfig { tribe, expiry_duration_ms }
///   TollConfigKey    → TollConfig { amount }  (stub — interface shape only)
///
/// Events emitted on posture change for demo observability.
module cc_posture::posture;

use cc_posture::config::{AdminCap, ExtensionConfig};

// === Constants ===
const BUSINESS: u8 = 0;
const DEFENSE: u8 = 1;

// === Errors ===
#[error(code = 0)]
const EInvalidPostureMode: vector<u8> = b"Invalid posture mode (must be 0 or 1)";

// === Structs ===

/// Current posture mode.
public struct PostureConfig has drop, store {
    mode: u8,
}

/// DF key for PostureConfig.
public struct PostureConfigKey has copy, drop, store {}

/// Tribe-only access configuration (active in DEFENSE mode).
public struct TribeConfig has drop, store {
    tribe: u32,
    expiry_duration_ms: u64,
}

/// DF key for TribeConfig.
public struct TribeConfigKey has copy, drop, store {}

/// Toll configuration (active in BUSINESS mode). Stub — amount tracked but not collected.
public struct TollConfig has drop, store {
    amount: u64,
}

/// DF key for TollConfig.
public struct TollConfigKey has copy, drop, store {}

// === Events ===

/// Emitted when the posture mode changes. Primary demo-proof artifact.
public struct PostureChangedEvent has copy, drop {
    config_id: ID,
    old_mode: u8,
    new_mode: u8,
}

// === Admin Functions ===

/// Set the posture mode (0 = BUSINESS, 1 = DEFENSE).
public fun set_posture(
    config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
    mode: u8,
) {
    assert!(mode == BUSINESS || mode == DEFENSE, EInvalidPostureMode);

    let config_id = object::id(config);
    let old_mode = if (config.has_rule<PostureConfigKey>(PostureConfigKey {})) {
        let old: PostureConfig = config.remove_rule(admin_cap, PostureConfigKey {});
        old.mode
    } else {
        255u8 // sentinel: no previous posture
    };

    config.add_rule(admin_cap, PostureConfigKey {}, PostureConfig { mode });

    sui::event::emit(PostureChangedEvent {
        config_id,
        old_mode,
        new_mode: mode,
    });
}

/// Set tribe-only access config (used in DEFENSE mode).
public fun set_tribe_config(
    config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
    tribe: u32,
    expiry_duration_ms: u64,
) {
    config.set_rule(admin_cap, TribeConfigKey {}, TribeConfig { tribe, expiry_duration_ms });
}

/// Remove tribe config (clearing defense-mode gate policy).
public fun clear_tribe_config(
    config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
) {
    if (config.has_rule<TribeConfigKey>(TribeConfigKey {})) {
        let _: TribeConfig = config.remove_rule(admin_cap, TribeConfigKey {});
    };
}

/// Set toll config (used in BUSINESS mode). Stub — records amount but does not collect.
public fun set_toll_config(
    config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
    amount: u64,
) {
    config.set_rule(admin_cap, TollConfigKey {}, TollConfig { amount });
}

/// Remove toll config (clearing business-mode gate policy).
public fun clear_toll_config(
    config: &mut ExtensionConfig,
    admin_cap: &AdminCap,
) {
    if (config.has_rule<TollConfigKey>(TollConfigKey {})) {
        let _: TollConfig = config.remove_rule(admin_cap, TollConfigKey {});
    };
}

// === View Functions ===

/// Returns current posture mode, or 255 if not set.
public fun current_posture(config: &ExtensionConfig): u8 {
    if (config.has_rule<PostureConfigKey>(PostureConfigKey {})) {
        config.borrow_rule<PostureConfigKey, PostureConfig>(PostureConfigKey {}).mode
    } else {
        255u8
    }
}

/// Whether defense (tribe) config is active.
public fun has_defense_config(config: &ExtensionConfig): bool {
    config.has_rule<TribeConfigKey>(TribeConfigKey {})
}

/// Whether business (toll) config is active.
public fun has_business_config(config: &ExtensionConfig): bool {
    config.has_rule<TollConfigKey>(TollConfigKey {})
}
