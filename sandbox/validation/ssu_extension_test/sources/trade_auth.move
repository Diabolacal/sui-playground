/// Extension witness for TradePost SSU access.
/// Defined in THIS package (separate from world-contracts) to validate
/// cross-package extension witness pattern (TP-05).
///
/// In production CivilizationControl, this module would live in the
/// cc_trade package and gate `withdraw_item` calls behind payment logic.
module ssu_extension_test::trade_auth;

/// Cross-package extension witness.
/// `drop` ability required by world::storage_unit::withdraw_item<Auth>.
public struct TradeAuth has drop {}

/// Package-scoped mint — only modules in this package can create TradeAuth.
/// Mirrors the canonical CC pattern: public(package) to prevent external forging.
public(package) fun trade_auth(): TradeAuth { TradeAuth {} }
