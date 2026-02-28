/// Extension config for atomic courier experiment.
/// Follows builder-scaffold pattern:
///   ExtensionConfig (shared singleton)
///   AdminCap (owned, key+store)
///   XAuth (drop-only, public(package) mint)
module atomic_courier_experiment::config;

public struct ExtensionConfig has key {
    id: UID,
}

public struct AdminCap has key, store {
    id: UID,
}

/// Auth witness for SSU/Gate extension authorization.
/// drop-only — cannot be stored or transferred.
public struct XAuth has drop {}

fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::transfer(admin_cap, ctx.sender());

    let config = ExtensionConfig { id: object::new(ctx) };
    transfer::share_object(config);
}

/// Mint an XAuth witness. Restricted to this package.
public(package) fun x_auth(): XAuth {
    XAuth {}
}
