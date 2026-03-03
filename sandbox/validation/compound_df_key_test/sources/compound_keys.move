/// Validates that compound dynamic field keys with embedded IDs produce
/// independent DFs on the same parent object. This is the foundation of
/// CivilizationControl's per-gate rule storage pattern.
///
/// Test scenarios:
/// 1. Same key type, different gate IDs → independent DFs
/// 2. Different key types, same gate ID → independent DFs
/// 3. Update one DF without affecting others
/// 4. Remove one DF without affecting others
module compound_df_key_test::compound_keys {
    use sui::dynamic_field as df;

    // ─── Key structs (mirror CivilizationControl pattern) ───

    /// Key for tribe filter rule, scoped to a specific gate
    public struct TribeRuleKey has copy, drop, store { gate_id: ID }

    /// Key for coin toll rule, scoped to a specific gate
    public struct TollRuleKey has copy, drop, store { gate_id: ID }

    /// Key for posture state, scoped to a specific gate
    public struct PostureKey has copy, drop, store { gate_id: ID }

    // ─── Value structs ───

    public struct TribeRule has store, drop { tribe_id: u64 }
    public struct TollRule has store, drop { price_mist: u64, treasury: address }
    public struct PostureState has store, drop { mode: u8 } // 0=BUSINESS, 1=DEFENSE

    // ─── Shared config object ───

    public struct ExtensionConfig has key {
        id: UID,
    }

    // ─── Errors ───

    #[error]
    const EUnexpectedValue: vector<u8> = b"Unexpected DF value";

    // ─── Tests ───

    #[test]
    /// Same key type (TribeRuleKey), different gate IDs → independent DFs
    fun test_same_key_type_different_gate_ids() {
        let mut ctx = tx_context::dummy();
        let mut config = ExtensionConfig { id: object::new(&mut ctx) };

        let gate_a = object::id_from_address(@0xA);
        let gate_b = object::id_from_address(@0xB);
        let gate_c = object::id_from_address(@0xC);

        // Add tribe rules for three different gates
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 1 });
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_b }, TribeRule { tribe_id: 2 });
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_c }, TribeRule { tribe_id: 3 });

        // Read back — each gate has its own independent rule
        let rule_a: &TribeRule = df::borrow(&config.id, TribeRuleKey { gate_id: gate_a });
        assert!(rule_a.tribe_id == 1, EUnexpectedValue);

        let rule_b: &TribeRule = df::borrow(&config.id, TribeRuleKey { gate_id: gate_b });
        assert!(rule_b.tribe_id == 2, EUnexpectedValue);

        let rule_c: &TribeRule = df::borrow(&config.id, TribeRuleKey { gate_id: gate_c });
        assert!(rule_c.tribe_id == 3, EUnexpectedValue);

        // Cleanup
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_b });
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_c });

        let ExtensionConfig { id } = config;
        object::delete(id);
    }

    #[test]
    /// Different key types (TribeRuleKey vs TollRuleKey), same gate ID → independent DFs
    fun test_different_key_types_same_gate_id() {
        let mut ctx = tx_context::dummy();
        let mut config = ExtensionConfig { id: object::new(&mut ctx) };

        let gate_a = object::id_from_address(@0xA);

        // Add both tribe and toll rules for the SAME gate
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 1 });
        df::add(&mut config.id, TollRuleKey { gate_id: gate_a }, TollRule { price_mist: 5_000_000_000, treasury: @0xDEAD });

        // Read back — both exist independently
        let tribe: &TribeRule = df::borrow(&config.id, TribeRuleKey { gate_id: gate_a });
        assert!(tribe.tribe_id == 1, EUnexpectedValue);

        let toll: &TollRule = df::borrow(&config.id, TollRuleKey { gate_id: gate_a });
        assert!(toll.price_mist == 5_000_000_000, EUnexpectedValue);
        assert!(toll.treasury == @0xDEAD, EUnexpectedValue);

        // Cleanup
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });
        let _: TollRule = df::remove(&mut config.id, TollRuleKey { gate_id: gate_a });

        let ExtensionConfig { id } = config;
        object::delete(id);
    }

    #[test]
    /// Full composition: 3 rule types × 2 gates = 6 independent DFs
    fun test_full_composition_matrix() {
        let mut ctx = tx_context::dummy();
        let mut config = ExtensionConfig { id: object::new(&mut ctx) };

        let gate_a = object::id_from_address(@0xA);
        let gate_b = object::id_from_address(@0xB);

        // Gate A: tribe=1, toll=5 SUI, posture=BUSINESS(0)
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 1 });
        df::add(&mut config.id, TollRuleKey { gate_id: gate_a }, TollRule { price_mist: 5_000_000_000, treasury: @0xA1 });
        df::add(&mut config.id, PostureKey { gate_id: gate_a }, PostureState { mode: 0 });

        // Gate B: tribe=2, toll=10 SUI, posture=DEFENSE(1)
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_b }, TribeRule { tribe_id: 2 });
        df::add(&mut config.id, TollRuleKey { gate_id: gate_b }, TollRule { price_mist: 10_000_000_000, treasury: @0xB1 });
        df::add(&mut config.id, PostureKey { gate_id: gate_b }, PostureState { mode: 1 });

        // Verify all 6 DFs are independent
        assert!(df::borrow<TribeRuleKey, TribeRule>(&config.id, TribeRuleKey { gate_id: gate_a }).tribe_id == 1, 0);
        assert!(df::borrow<TribeRuleKey, TribeRule>(&config.id, TribeRuleKey { gate_id: gate_b }).tribe_id == 2, 1);
        assert!(df::borrow<TollRuleKey, TollRule>(&config.id, TollRuleKey { gate_id: gate_a }).price_mist == 5_000_000_000, 2);
        assert!(df::borrow<TollRuleKey, TollRule>(&config.id, TollRuleKey { gate_id: gate_b }).price_mist == 10_000_000_000, 3);
        assert!(df::borrow<PostureKey, PostureState>(&config.id, PostureKey { gate_id: gate_a }).mode == 0, 4);
        assert!(df::borrow<PostureKey, PostureState>(&config.id, PostureKey { gate_id: gate_b }).mode == 1, 5);

        // Cleanup all 6
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_b });
        let _: TollRule = df::remove(&mut config.id, TollRuleKey { gate_id: gate_a });
        let _: TollRule = df::remove(&mut config.id, TollRuleKey { gate_id: gate_b });
        let _: PostureState = df::remove(&mut config.id, PostureKey { gate_id: gate_a });
        let _: PostureState = df::remove(&mut config.id, PostureKey { gate_id: gate_b });

        let ExtensionConfig { id } = config;
        object::delete(id);
    }

    #[test]
    /// Update one DF without affecting others
    fun test_update_independence() {
        let mut ctx = tx_context::dummy();
        let mut config = ExtensionConfig { id: object::new(&mut ctx) };

        let gate_a = object::id_from_address(@0xA);

        // Initial state
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 1 });
        df::add(&mut config.id, TollRuleKey { gate_id: gate_a }, TollRule { price_mist: 5_000_000_000, treasury: @0xA1 });

        // Update tribe rule only
        let old_tribe: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });
        assert!(old_tribe.tribe_id == 1, 0);
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 99 });

        // Verify tribe updated, toll unchanged
        assert!(df::borrow<TribeRuleKey, TribeRule>(&config.id, TribeRuleKey { gate_id: gate_a }).tribe_id == 99, 1);
        assert!(df::borrow<TollRuleKey, TollRule>(&config.id, TollRuleKey { gate_id: gate_a }).price_mist == 5_000_000_000, 2);

        // Cleanup
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });
        let _: TollRule = df::remove(&mut config.id, TollRuleKey { gate_id: gate_a });

        let ExtensionConfig { id } = config;
        object::delete(id);
    }

    #[test]
    /// Remove one DF without affecting others
    fun test_remove_independence() {
        let mut ctx = tx_context::dummy();
        let mut config = ExtensionConfig { id: object::new(&mut ctx) };

        let gate_a = object::id_from_address(@0xA);

        // Add both rules
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 1 });
        df::add(&mut config.id, TollRuleKey { gate_id: gate_a }, TollRule { price_mist: 5_000_000_000, treasury: @0xA1 });

        // Remove tribe rule only
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });

        // Verify tribe is gone
        assert!(!df::exists_(&config.id, TribeRuleKey { gate_id: gate_a }), 0);

        // Verify toll still exists
        assert!(df::exists_(&config.id, TollRuleKey { gate_id: gate_a }), 1);
        assert!(df::borrow<TollRuleKey, TollRule>(&config.id, TollRuleKey { gate_id: gate_a }).price_mist == 5_000_000_000, 2);

        // Cleanup
        let _: TollRule = df::remove(&mut config.id, TollRuleKey { gate_id: gate_a });

        let ExtensionConfig { id } = config;
        object::delete(id);
    }

    #[test]
    /// Verify df::exists_ works correctly with compound keys
    fun test_exists_check() {
        let mut ctx = tx_context::dummy();
        let mut config = ExtensionConfig { id: object::new(&mut ctx) };

        let gate_a = object::id_from_address(@0xA);
        let gate_b = object::id_from_address(@0xB);

        // Only add for gate_a
        df::add(&mut config.id, TribeRuleKey { gate_id: gate_a }, TribeRule { tribe_id: 1 });

        // gate_a exists, gate_b does not
        assert!(df::exists_(&config.id, TribeRuleKey { gate_id: gate_a }), 0);
        assert!(!df::exists_(&config.id, TribeRuleKey { gate_id: gate_b }), 1);

        // Neither toll key exists
        assert!(!df::exists_(&config.id, TollRuleKey { gate_id: gate_a }), 2);
        assert!(!df::exists_(&config.id, TollRuleKey { gate_id: gate_b }), 3);

        // Cleanup
        let _: TribeRule = df::remove(&mut config.id, TribeRuleKey { gate_id: gate_a });

        let ExtensionConfig { id } = config;
        object::delete(id);
    }
}
