/// Gate Toll Validation Module
///
/// PURPOSE: Validate that a coin-based toll can be composed with gate access
/// control in a single PTB. Simulates the extension pattern without
/// depending on world-contracts.
///
/// THIS IS SANDBOX CODE — DO NOT COPY TO HACKATHON SUBMISSION.
/// Reimplement from scratch on March 11 using world-contracts gate extension pattern.
///
/// What this validates:
/// 1. Dynamic field rule storage (tribe filter + coin toll as composable rules)
/// 2. Coin<SUI> transfer as toll payment in a single PTB
/// 3. Shared config object for rule parameters
/// 4. Pass/fail gate check with multiple rule types
///
/// What this does NOT validate (deferred to hackathon):
/// - issue_jump_permit / jump_with_permit on actual Gate objects
/// - AdminACL / sponsored transaction pattern
/// - link_gates / distance proofs
///
/// The world-contracts unit tests already prove extension-based gate jumping
/// works (test_jump_with_permit_succeeds in gate_tests.move L291).
module gate_toll_validation::gate_toll {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use sui::dynamic_field;

    // ========== Error Codes ==========

    const ETribeMismatch: u64 = 0;
    const ETollInsufficient: u64 = 1;
    const ENotOwner: u64 = 2;

    // ========== Types ==========

    /// Simulates a gate with extension-based access control.
    /// In the real system, this is world::gate::Gate with authorize_extension<Auth>.
    public struct GateConfig has key {
        id: UID,
        owner: address,
        collector: address,     // where toll payments go
    }

    /// Dynamic field key for tribe filter rule
    public struct TribeRuleKey has copy, drop, store {}

    /// Tribe filter rule — stored as dynamic field on GateConfig
    public struct TribeRule has store {
        allowed_tribe: u32,
    }

    /// Dynamic field key for toll rule
    public struct TollRuleKey has copy, drop, store {}

    /// Toll rule — stored as dynamic field on GateConfig
    public struct TollRule has store {
        price: u64,
    }

    /// Simulates a character with a tribe affiliation
    public struct MockCharacter has key {
        id: UID,
        tribe: u32,
        owner: address,
    }

    /// Proof that gate access was granted (simulates JumpPermit)
    public struct AccessGrant has key {
        id: UID,
        gate_id: address,
        character_id: address,
    }

    // ========== Events ==========

    public struct GateCreated has copy, drop {
        gate_id: address,
        owner: address,
    }

    public struct TribeRuleSet has copy, drop {
        gate_id: address,
        allowed_tribe: u32,
    }

    public struct TollRuleSet has copy, drop {
        gate_id: address,
        price: u64,
    }

    public struct TollPaid has copy, drop {
        gate_id: address,
        traveler: address,
        amount: u64,
    }

    public struct AccessGranted has copy, drop {
        gate_id: address,
        character_id: address,
        traveler: address,
    }

    public struct AccessDenied has copy, drop {
        gate_id: address,
        character_id: address,
        reason: vector<u8>,
    }

    // ========== Owner Functions ==========

    /// Create a gate with toll collection address
    public fun create_gate(
        collector: address,
        ctx: &mut TxContext,
    ) {
        let gate = GateConfig {
            id: object::new(ctx),
            owner: ctx.sender(),
            collector,
        };
        event::emit(GateCreated {
            gate_id: object::id_address(&gate),
            owner: ctx.sender(),
        });
        transfer::share_object(gate);
    }

    /// Set tribe filter rule (dynamic field on gate)
    public fun set_tribe_rule(
        gate: &mut GateConfig,
        allowed_tribe: u32,
        ctx: &mut TxContext,
    ) {
        assert!(ctx.sender() == gate.owner, ENotOwner);

        if (dynamic_field::exists_(&gate.id, TribeRuleKey {})) {
            let rule: &mut TribeRule = dynamic_field::borrow_mut(&mut gate.id, TribeRuleKey {});
            rule.allowed_tribe = allowed_tribe;
        } else {
            dynamic_field::add(&mut gate.id, TribeRuleKey {}, TribeRule { allowed_tribe });
        };

        event::emit(TribeRuleSet {
            gate_id: object::id_address(gate),
            allowed_tribe,
        });
    }

    /// Set toll rule (dynamic field on gate)
    public fun set_toll_rule(
        gate: &mut GateConfig,
        price: u64,
        ctx: &mut TxContext,
    ) {
        assert!(ctx.sender() == gate.owner, ENotOwner);

        if (dynamic_field::exists_(&gate.id, TollRuleKey {})) {
            let rule: &mut TollRule = dynamic_field::borrow_mut(&mut gate.id, TollRuleKey {});
            rule.price = price;
        } else {
            dynamic_field::add(&mut gate.id, TollRuleKey {}, TollRule { price });
        };

        event::emit(TollRuleSet {
            gate_id: object::id_address(gate),
            price,
        });
    }

    // ========== Character ==========

    /// Create a mock character with tribe affiliation
    public fun create_character(
        tribe: u32,
        ctx: &mut TxContext,
    ) {
        let character = MockCharacter {
            id: object::new(ctx),
            tribe,
            owner: ctx.sender(),
        };
        transfer::transfer(character, ctx.sender());
    }

    // ========== Traveler Functions ==========

    /// Request gate access — checks all configured rules.
    /// If tribe rule exists: character tribe must match.
    /// If toll rule exists: payment must be sufficient.
    /// On success: issues an AccessGrant (simulates JumpPermit).
    public fun request_access(
        gate: &GateConfig,
        character: &MockCharacter,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let gate_addr = object::id_address(gate);
        let char_addr = object::id_address(character);

        // Check tribe rule if configured
        if (dynamic_field::exists_(&gate.id, TribeRuleKey {})) {
            let rule: &TribeRule = dynamic_field::borrow(&gate.id, TribeRuleKey {});
            assert!(character.tribe == rule.allowed_tribe, ETribeMismatch);
        };

        // Check toll rule if configured
        if (dynamic_field::exists_(&gate.id, TollRuleKey {})) {
            let rule: &TollRule = dynamic_field::borrow(&gate.id, TollRuleKey {});
            assert!(coin::value(&payment) >= rule.price, ETollInsufficient);

            event::emit(TollPaid {
                gate_id: gate_addr,
                traveler: ctx.sender(),
                amount: coin::value(&payment),
            });

            // Transfer toll payment to collector
            transfer::public_transfer(payment, gate.collector);
        } else {
            // No toll — return payment to sender
            transfer::public_transfer(payment, ctx.sender());
        };

        // Issue access grant (simulates JumpPermit)
        let grant = AccessGrant {
            id: object::new(ctx),
            gate_id: gate_addr,
            character_id: char_addr,
        };

        event::emit(AccessGranted {
            gate_id: gate_addr,
            character_id: char_addr,
            traveler: ctx.sender(),
        });

        transfer::transfer(grant, ctx.sender());
    }
}
