/// CivilizationControl shared extension configuration.
///
/// Follows the builder-scaffold smart_gate_extension::config pattern
/// (renamed from smart_gate::config in scaffold v3c65b22, 2026-03-10):
/// - Shared `ExtensionConfig` for dynamic-field-based rule storage
/// - `AdminCap` for config mutation
/// - `XAuth` typed witness for gate extension authorization
module cc_posture::config;

use sui::dynamic_field as df;

public struct ExtensionConfig has key {
    id: UID,
}

public struct AdminCap has key, store {
    id: UID,
}

/// Typed witness for gate extension authorization.
/// Package-scoped to prevent external packages from forging.
public struct XAuth has drop {}

fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::transfer(admin_cap, ctx.sender());

    let config = ExtensionConfig { id: object::new(ctx) };
    transfer::share_object(config);
}

// === Dynamic field helpers ===

public fun has_rule<K: copy + drop + store>(config: &ExtensionConfig, key: K): bool {
    df::exists_(&config.id, key)
}

public fun borrow_rule<K: copy + drop + store, V: store>(
    config: &ExtensionConfig,
    key: K,
): &V {
    df::borrow(&config.id, key)
}

public fun add_rule<K: copy + drop + store, V: store>(
    config: &mut ExtensionConfig,
    _: &AdminCap,
    key: K,
    value: V,
) {
    df::add(&mut config.id, key, value);
}

/// Insert-or-overwrite a rule. If a value already exists for `key`, it is
/// removed and dropped before the new value is inserted.
public fun set_rule<K: copy + drop + store, V: store + drop>(
    config: &mut ExtensionConfig,
    _: &AdminCap,
    key: K,
    value: V,
) {
    if (df::exists_(&config.id, copy key)) {
        let _old: V = df::remove(&mut config.id, copy key);
    };
    df::add(&mut config.id, key, value);
}

public fun remove_rule<K: copy + drop + store, V: store>(
    config: &mut ExtensionConfig,
    _: &AdminCap,
    key: K,
): V {
    df::remove(&mut config.id, key)
}

/// Mint an `XAuth` witness. Restricted to this package.
public(package) fun x_auth(): XAuth {
    XAuth {}
}
