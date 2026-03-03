/// TP-05 Validation: SSU withdraw_item<Auth> against real world-contracts
///
/// Validates cross-package extension witness pattern with world-contracts v0.0.15.
/// Claims tested:
///   TP-05: Extension witness enables cross-address withdrawal from real SSU
///   TP-05a: deposit_to_owned enables cross-player delivery
///   TP-05b: Partial quantity withdrawal (v0.0.15 feature)
///   TP-05c: Wrong extension type aborts
///   TP-05d: parent_id enforcement (items return to origin SSU only)
///   TP-05e: Full trade flow: withdraw + deliver + verify balances
#[test_only]
module ssu_extension_test::ssu_tests;

use std::string::utf8;
use std::unit_test::assert_eq;
use sui::{clock, test_scenario as ts};
use world::{
    access::{OwnerCap, AdminACL},
    character::{Self, Character},
    energy::EnergyConfig,
    inventory,
    network_node::{Self, NetworkNode},
    object_registry::ObjectRegistry,
    storage_unit::{Self, StorageUnit},
    test_helpers::{Self, admin, user_a, user_b, tenant},
};
use ssu_extension_test::trade_auth::{Self, TradeAuth};

// === Fake witness for negative test ===
public struct FakeAuth has drop {}

// === Constants matching test_helpers and storage_unit_tests ===
const CHARACTER_A_ITEM_ID: u32 = 1234;
const CHARACTER_B_ITEM_ID: u32 = 5678;
const LOCATION_HASH: vector<u8> =
    x"7a8f3b2e9c4d1a6f5e8b2d9c3f7a1e5b7a8f3b2e9c4d1a6f5e8b2d9c3f7a1e5b";
const MAX_CAPACITY: u64 = 100000;
// SSU_TYPE_ID must match test_helpers::assembly_type_2() = 5555 for energy config
const SSU_TYPE_ID: u64 = 5555;
const SSU_ITEM_ID: u64 = 90002;

// Item constants
const AMMO_TYPE_ID: u64 = 88069;
const AMMO_ITEM_ID: u64 = 1000004145107;
const AMMO_VOLUME: u64 = 100;
const AMMO_QUANTITY: u32 = 10;

// Network node constants
const MS_PER_SECOND: u64 = 1000;
const NWN_TYPE_ID: u64 = 111000;
const NWN_ITEM_ID: u64 = 5000;
const FUEL_MAX_CAPACITY: u64 = 1000;
const FUEL_BURN_RATE_IN_MS: u64 = 3600 * MS_PER_SECOND;
const MAX_PRODUCTION: u64 = 100;
const FUEL_TYPE_ID: u64 = 1;
const FUEL_VOLUME: u64 = 10;

// === Infrastructure Helpers ===

/// Full world bootstrap: AdminACL, GovernorCap, registries, fuel/energy configs
fun setup(ts: &mut ts::Scenario) {
    test_helpers::setup_world(ts);
    test_helpers::configure_assembly_energy(ts);
    test_helpers::configure_fuel(ts);
    test_helpers::register_server_address(ts);
}

/// Create a Character for `user` and share it. Returns character ID.
fun create_character(ts: &mut ts::Scenario, user: address, item_id: u32): ID {
    ts::next_tx(ts, admin());
    let admin_acl = ts::take_shared<AdminACL>(ts);
    let mut registry = ts::take_shared<ObjectRegistry>(ts);
    let character = character::create_character(
        &mut registry,
        &admin_acl,
        item_id,
        tenant(),
        100, // tribe_id
        user,
        utf8(b"test_character"),
        ts.ctx(),
    );
    let character_id = object::id(&character);
    character.share_character(&admin_acl, ts.ctx());
    ts::return_shared(registry);
    ts::return_shared(admin_acl);
    character_id
}

/// Create a NetworkNode anchored to `character_id`. Returns NWN ID.
fun create_network_node(ts: &mut ts::Scenario, character_id: ID): ID {
    ts::next_tx(ts, admin());
    let mut registry = ts::take_shared<ObjectRegistry>(ts);
    let character = ts::take_shared_by_id<Character>(ts, character_id);
    let admin_acl = ts::take_shared<AdminACL>(ts);
    let nwn = network_node::anchor(
        &mut registry,
        &character,
        &admin_acl,
        NWN_ITEM_ID,
        NWN_TYPE_ID,
        LOCATION_HASH,
        FUEL_MAX_CAPACITY,
        FUEL_BURN_RATE_IN_MS,
        MAX_PRODUCTION,
        ts.ctx(),
    );
    let id = object::id(&nwn);
    nwn.share_network_node(&admin_acl, ts.ctx());
    ts::return_shared(character);
    ts::return_shared(admin_acl);
    ts::return_shared(registry);
    id
}

/// Create an SSU anchored to NWN. Returns SSU ID.
fun create_ssu(ts: &mut ts::Scenario, character_id: ID, nwn_id: ID): ID {
    ts::next_tx(ts, admin());
    let mut registry = ts::take_shared<ObjectRegistry>(ts);
    let mut nwn = ts::take_shared_by_id<NetworkNode>(ts, nwn_id);
    let character = ts::take_shared_by_id<Character>(ts, character_id);
    let admin_acl = ts::take_shared<AdminACL>(ts);
    let storage_unit = storage_unit::anchor(
        &mut registry,
        &mut nwn,
        &character,
        &admin_acl,
        SSU_ITEM_ID,
        SSU_TYPE_ID,
        MAX_CAPACITY,
        LOCATION_HASH,
        ts.ctx(),
    );
    let ssu_id = object::id(&storage_unit);
    storage_unit.share_storage_unit(&admin_acl, ts.ctx());
    ts::return_shared(admin_acl);
    ts::return_shared(character);
    ts::return_shared(registry);
    ts::return_shared(nwn);
    ssu_id
}

/// Deposit fuel, bring NWN online, then SSU online.
fun bring_online(
    ts: &mut ts::Scenario,
    user: address,
    character_id: ID,
    ssu_id: ID,
    nwn_id: ID,
) {
    let clock = clock::create_for_testing(ts.ctx());

    // Step 1: Borrow NWN OwnerCap, deposit fuel, bring NWN online
    ts::next_tx(ts, user);
    let mut character = ts::take_shared_by_id<Character>(ts, character_id);
    let (nwn_cap, nwn_receipt) = character.borrow_owner_cap<NetworkNode>(
        ts::most_recent_receiving_ticket<OwnerCap<NetworkNode>>(&character_id),
        ts.ctx(),
    );

    ts::next_tx(ts, user);
    {
        let mut nwn = ts::take_shared_by_id<NetworkNode>(ts, nwn_id);
        nwn.deposit_fuel_test(&nwn_cap, FUEL_TYPE_ID, FUEL_VOLUME, 10, &clock);
        ts::return_shared(nwn);
    };

    ts::next_tx(ts, user);
    {
        let mut nwn = ts::take_shared_by_id<NetworkNode>(ts, nwn_id);
        nwn.online(&nwn_cap, &clock);
        ts::return_shared(nwn);
    };
    character.return_owner_cap(nwn_cap, nwn_receipt);

    // Step 2: Borrow SSU OwnerCap, bring SSU online
    ts::next_tx(ts, user);
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let mut nwn = ts::take_shared_by_id<NetworkNode>(ts, nwn_id);
        let energy_config = ts::take_shared<EnergyConfig>(ts);
        let (ssu_cap, ssu_receipt) = character.borrow_owner_cap<StorageUnit>(
            ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&character_id),
            ts.ctx(),
        );
        ssu.online(&mut nwn, &energy_config, &ssu_cap);
        character.return_owner_cap(ssu_cap, ssu_receipt);
        ts::return_shared(ssu);
        ts::return_shared(nwn);
        ts::return_shared(energy_config);
    };

    ts::return_shared(character);
    clock.destroy_for_testing();
}

/// Mint AMMO items into SSU's main inventory (test-only helper).
fun mint_items(
    ts: &mut ts::Scenario,
    ssu_id: ID,
    character_id: ID,
    user: address,
    quantity: u32,
) {
    ts::next_tx(ts, user);
    let mut character = ts::take_shared_by_id<Character>(ts, character_id);
    let (owner_cap, receipt) = character.borrow_owner_cap<StorageUnit>(
        ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&character_id),
        ts.ctx(),
    );
    let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
    ssu.game_item_to_chain_inventory_test<StorageUnit>(
        &character,
        &owner_cap,
        AMMO_ITEM_ID,
        AMMO_TYPE_ID,
        AMMO_VOLUME,
        quantity,
        ts.ctx(),
    );
    character.return_owner_cap(owner_cap, receipt);
    ts::return_shared(character);
    ts::return_shared(ssu);
}

/// Authorize TradeAuth extension on SSU (owner operation).
fun authorize_trade_extension(
    ts: &mut ts::Scenario,
    user: address,
    character_id: ID,
    ssu_id: ID,
) {
    ts::next_tx(ts, user);
    let mut character = ts::take_shared_by_id<Character>(ts, character_id);
    let (owner_cap, receipt) = character.borrow_owner_cap<StorageUnit>(
        ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&character_id),
        ts.ctx(),
    );
    let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
    ssu.authorize_extension<TradeAuth>(&owner_cap);
    character.return_owner_cap(owner_cap, receipt);
    ts::return_shared(ssu);
    ts::return_shared(character);
}

/// Full bootstrap: world → character → NWN → SSU → online → items → authorize extension.
/// Returns (character_id, ssu_id, nwn_id).
fun full_setup(ts: &mut ts::Scenario): (ID, ID, ID) {
    setup(ts);
    let char_id = create_character(ts, user_a(), CHARACTER_A_ITEM_ID);
    let nwn_id = create_network_node(ts, char_id);
    let ssu_id = create_ssu(ts, char_id, nwn_id);
    bring_online(ts, user_a(), char_id, ssu_id, nwn_id);
    mint_items(ts, ssu_id, char_id, user_a(), AMMO_QUANTITY);
    authorize_trade_extension(ts, user_a(), char_id, ssu_id);
    (char_id, ssu_id, nwn_id)
}

// === TESTS ===

/// TP-05 core: Cross-package extension authorizes + withdraws from real SSU.
/// Proves: `withdraw_item<TradeAuth>` works when TradeAuth is from external package.
#[test]
fun test_cross_package_withdraw_item() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (char_id, ssu_id, _nwn_id) = full_setup(ts);

    // Withdraw with our cross-package TradeAuth witness
    ts::next_tx(ts, user_a());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character = ts::take_shared_by_id<Character>(ts, char_id);
        let item = ssu.withdraw_item<TradeAuth>(
            &character,
            trade_auth::trade_auth(),
            AMMO_TYPE_ID,
            AMMO_QUANTITY,
            ts.ctx(),
        );

        // Verify Item fields
        assert_eq!(inventory::type_id(&item), AMMO_TYPE_ID);
        assert_eq!(inventory::quantity(&item), AMMO_QUANTITY);
        assert_eq!(inventory::parent_id(&item), ssu_id);

        // Transfer item to caller (simulates buyer receiving goods)
        transfer::public_transfer(item, user_a());
        ts::return_shared(ssu);
        ts::return_shared(character);
    };

    ts::end(scenario);
}

/// TP-05 buyer scenario: Non-owner address withdraws via extension auth.
/// Proves: `withdraw_item<TradeAuth>` does NOT require OwnerCap or sender == owner.
#[test]
fun test_non_owner_withdraw_via_extension() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (char_a_id, ssu_id, _nwn_id) = full_setup(ts);

    // Create a second character for the buyer (user_b)
    let char_b_id = create_character(ts, user_b(), CHARACTER_B_ITEM_ID);

    // User B (buyer, non-owner) withdraws from User A's SSU
    ts::next_tx(ts, user_b());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character_b = ts::take_shared_by_id<Character>(ts, char_b_id);
        let item = ssu.withdraw_item<TradeAuth>(
            &character_b,
            trade_auth::trade_auth(),
            AMMO_TYPE_ID,
            AMMO_QUANTITY,
            ts.ctx(),
        );

        // Buyer receives the item
        assert_eq!(inventory::type_id(&item), AMMO_TYPE_ID);
        assert_eq!(inventory::quantity(&item), AMMO_QUANTITY);
        assert_eq!(inventory::parent_id(&item), ssu_id);
        transfer::public_transfer(item, user_b());
        ts::return_shared(ssu);
        ts::return_shared(character_b);
    };

    // Verify SSU inventory is depleted
    ts::next_tx(ts, user_a());
    {
        let mut character_a = ts::take_shared_by_id<Character>(ts, char_a_id);
        let (owner_cap, receipt) = character_a.borrow_owner_cap<StorageUnit>(
            ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&char_a_id),
            ts.ctx(),
        );
        let ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let owner_cap_id = object::id(&owner_cap);
        assert!(!storage_unit::contains_item(&ssu, owner_cap_id, AMMO_TYPE_ID), 0);
        character_a.return_owner_cap(owner_cap, receipt);
        ts::return_shared(ssu);
        ts::return_shared(character_a);
    };

    ts::end(scenario);
}

/// TP-05a: deposit_to_owned delivers withdrawn item to buyer's owned inventory.
/// Proves: cross-player delivery without OwnerCap sharing.
#[test]
fun test_deposit_to_owned_delivery() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (_char_a_id, ssu_id, _nwn_id) = full_setup(ts);
    let char_b_id = create_character(ts, user_b(), CHARACTER_B_ITEM_ID);

    // Withdraw + deposit_to_owned in same tx (simulates buy function)
    ts::next_tx(ts, user_b());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character_b = ts::take_shared_by_id<Character>(ts, char_b_id);

        // Step 1: Extension-authorized withdrawal from SSU main inventory
        let item = ssu.withdraw_item<TradeAuth>(
            &character_b,
            trade_auth::trade_auth(),
            AMMO_TYPE_ID,
            AMMO_QUANTITY,
            ts.ctx(),
        );

        // Step 2: Deposit into buyer's owned inventory at same SSU
        ssu.deposit_to_owned<TradeAuth>(
            &character_b,
            item,
            trade_auth::trade_auth(),
            ts.ctx(),
        );

        ts::return_shared(ssu);
        ts::return_shared(character_b);
    };

    // Verify buyer's owned inventory was created and contains the item
    ts::next_tx(ts, user_b());
    {
        let mut character_b = ts::take_shared_by_id<Character>(ts, char_b_id);
        let (owner_cap, receipt) = character_b.borrow_owner_cap<Character>(
            ts::most_recent_receiving_ticket<OwnerCap<Character>>(&char_b_id),
            ts.ctx(),
        );
        let ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let owner_cap_id = object::id(&owner_cap);
        assert!(storage_unit::contains_item(&ssu, owner_cap_id, AMMO_TYPE_ID), 0);
        assert_eq!(storage_unit::item_quantity(&ssu, owner_cap_id, AMMO_TYPE_ID), AMMO_QUANTITY);
        character_b.return_owner_cap(owner_cap, receipt);
        ts::return_shared(ssu);
        ts::return_shared(character_b);
    };

    ts::end(scenario);
}

/// TP-05b: Partial quantity withdrawal (v0.0.15 feature).
/// Proves: withdraw less than full stock, remainder stays in SSU.
#[test]
fun test_partial_quantity_withdraw() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (char_id, ssu_id, _nwn_id) = full_setup(ts);

    // Withdraw 3 of 10 items
    ts::next_tx(ts, user_a());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character = ts::take_shared_by_id<Character>(ts, char_id);
        let item = ssu.withdraw_item<TradeAuth>(
            &character,
            trade_auth::trade_auth(),
            AMMO_TYPE_ID,
            3, // partial quantity
            ts.ctx(),
        );

        assert_eq!(inventory::quantity(&item), 3);
        transfer::public_transfer(item, user_a());
        ts::return_shared(ssu);
        ts::return_shared(character);
    };

    // Verify 7 remaining
    ts::next_tx(ts, user_a());
    {
        let mut character = ts::take_shared_by_id<Character>(ts, char_id);
        let (owner_cap, receipt) = character.borrow_owner_cap<StorageUnit>(
            ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&char_id),
            ts.ctx(),
        );
        let ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let owner_cap_id = object::id(&owner_cap);
        assert_eq!(storage_unit::item_quantity(&ssu, owner_cap_id, AMMO_TYPE_ID), 7);
        character.return_owner_cap(owner_cap, receipt);
        ts::return_shared(ssu);
        ts::return_shared(character);
    };

    ts::end(scenario);
}

/// TP-05c: Wrong extension type aborts.
/// Proves: withdraw_item<FakeAuth> fails when SSU has TradeAuth extension.
#[test, expected_failure(abort_code = storage_unit::EExtensionNotAuthorized)]
fun test_wrong_extension_aborts() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (char_id, ssu_id, _nwn_id) = full_setup(ts);

    // Attempt withdrawal with wrong witness type
    ts::next_tx(ts, user_a());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character = ts::take_shared_by_id<Character>(ts, char_id);
        let item = ssu.withdraw_item<FakeAuth>(
            &character,
            FakeAuth {},
            AMMO_TYPE_ID,
            AMMO_QUANTITY,
            ts.ctx(),
        );
        // Should never reach here
        transfer::public_transfer(item, user_a());
        ts::return_shared(ssu);
        ts::return_shared(character);
    };

    ts::end(scenario);
}

/// TP-05d: parent_id enforcement — items can only return to origin SSU.
/// Proves: deposit_item checks parent_id match (v0.0.15).
/// Note: We do NOT test cross-SSU deposit here (would need 2 SSUs + 2 items).
/// Instead we verify the parent_id field is correctly set to the source SSU.
#[test]
fun test_parent_id_set_correctly() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (char_id, ssu_id, _nwn_id) = full_setup(ts);

    // Withdraw and verify parent_id matches source SSU
    ts::next_tx(ts, user_a());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character = ts::take_shared_by_id<Character>(ts, char_id);
        let item = ssu.withdraw_item<TradeAuth>(
            &character,
            trade_auth::trade_auth(),
            AMMO_TYPE_ID,
            AMMO_QUANTITY,
            ts.ctx(),
        );

        // parent_id MUST equal the SSU we withdrew from
        assert_eq!(inventory::parent_id(&item), ssu_id);

        // Deposit back to SAME SSU succeeds (parent_id matches)
        ssu.deposit_item<TradeAuth>(
            &character,
            item,
            trade_auth::trade_auth(),
            ts.ctx(),
        );

        ts::return_shared(ssu);
        ts::return_shared(character);
    };

    ts::end(scenario);
}

/// TP-05e: Full trade flow — withdraw from seller's SSU, deliver to buyer, verify balances.
/// Proves: The complete TradePost pattern works end-to-end.
#[test]
fun test_full_trade_flow() {
    let mut scenario = ts::begin(admin());
    let ts = &mut scenario;
    let (char_a_id, ssu_id, _nwn_id) = full_setup(ts);
    let char_b_id = create_character(ts, user_b(), CHARACTER_B_ITEM_ID);

    // Verify initial state: seller has AMMO_QUANTITY items
    ts::next_tx(ts, user_a());
    {
        let mut character_a = ts::take_shared_by_id<Character>(ts, char_a_id);
        let (owner_cap, receipt) = character_a.borrow_owner_cap<StorageUnit>(
            ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&char_a_id),
            ts.ctx(),
        );
        let ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let owner_cap_id = object::id(&owner_cap);
        assert_eq!(storage_unit::item_quantity(&ssu, owner_cap_id, AMMO_TYPE_ID), AMMO_QUANTITY);
        character_a.return_owner_cap(owner_cap, receipt);
        ts::return_shared(ssu);
        ts::return_shared(character_a);
    };

    // TRADE: Buyer withdraws and receives items (simulates buy() function body)
    ts::next_tx(ts, user_b());
    {
        let mut ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let character_b = ts::take_shared_by_id<Character>(ts, char_b_id);

        let buy_quantity: u32 = 5;

        // Extension-authorized withdraw from seller's SSU
        let item = ssu.withdraw_item<TradeAuth>(
            &character_b,
            trade_auth::trade_auth(),
            AMMO_TYPE_ID,
            buy_quantity,
            ts.ctx(),
        );

        // Deliver to buyer's owned inventory at this SSU
        ssu.deposit_to_owned<TradeAuth>(
            &character_b,
            item,
            trade_auth::trade_auth(),
            ts.ctx(),
        );

        ts::return_shared(ssu);
        ts::return_shared(character_b);
    };

    // Verify final state: seller has 5 remaining, buyer has 5
    ts::next_tx(ts, user_a());
    {
        let mut character_a = ts::take_shared_by_id<Character>(ts, char_a_id);
        let (owner_cap, receipt) = character_a.borrow_owner_cap<StorageUnit>(
            ts::most_recent_receiving_ticket<OwnerCap<StorageUnit>>(&char_a_id),
            ts.ctx(),
        );
        let ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let seller_cap_id = object::id(&owner_cap);
        assert_eq!(storage_unit::item_quantity(&ssu, seller_cap_id, AMMO_TYPE_ID), 5);
        character_a.return_owner_cap(owner_cap, receipt);
        ts::return_shared(ssu);
        ts::return_shared(character_a);
    };

    ts::next_tx(ts, user_b());
    {
        let mut character_b = ts::take_shared_by_id<Character>(ts, char_b_id);
        let (owner_cap, receipt) = character_b.borrow_owner_cap<Character>(
            ts::most_recent_receiving_ticket<OwnerCap<Character>>(&char_b_id),
            ts.ctx(),
        );
        let ssu = ts::take_shared_by_id<StorageUnit>(ts, ssu_id);
        let buyer_cap_id = object::id(&owner_cap);
        assert_eq!(storage_unit::item_quantity(&ssu, buyer_cap_id, AMMO_TYPE_ID), 5);
        character_b.return_owner_cap(owner_cap, receipt);
        ts::return_shared(ssu);
        ts::return_shared(character_b);
    };

    ts::end(scenario);
}
