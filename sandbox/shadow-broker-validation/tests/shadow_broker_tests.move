#[test_only]
module shadow_broker::shadow_broker_tests;

use sui::test_scenario;
use sui::coin;
use sui::sui::SUI;
use std::unit_test::destroy;
use shadow_broker::intel_object::{Self, IntelObject};
use shadow_broker::marketplace::{Self, Listing};

// === Helpers ===

const CREATOR: address = @0xA;
const BUYER: address = @0xB;
const RANDOM: address = @0xC;

fun mint_test_intel(ctx: &mut TxContext): IntelObject {
    intel_object::mint(
        b"blob_abc123".to_string(),
        vector[],
        b"audio/mp3".to_string(),
        120,
        1048576,
        b"Fleet movements near X-7OMU".to_string(),
        option::some(b"teaser_xyz789".to_string()),
        ctx,
    )
}

// === intel_object tests ===

#[test]
fun mint_and_read() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);

        assert!(*intel.blob_id() == b"blob_abc123".to_string());
        assert!(*intel.encrypted_key() == vector[]);
        assert!(*intel.file_type() == b"audio/mp3".to_string());
        assert!(intel.duration_seconds() == 120);
        assert!(intel.file_size_bytes() == 1048576);
        assert!(*intel.description() == b"Fleet movements near X-7OMU".to_string());
        assert!(intel.creator() == CREATOR);
        assert!(intel.teaser_blob_id().is_some());

        destroy(intel);
    };
    scenario.end();
}

#[test]
fun update_encrypted_key_succeeds() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let mut intel = mint_test_intel(ctx);
        let key = vector[1, 2, 3, 4, 5];
        intel.update_encrypted_key(key, ctx);
        assert!(*intel.encrypted_key() == vector[1, 2, 3, 4, 5]);
        destroy(intel);
    };
    scenario.end();
}

#[test, expected_failure(abort_code = intel_object::ENotCreator)]
fun update_encrypted_key_wrong_caller_aborts() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);
        transfer::public_transfer(intel, CREATOR);
    };
    scenario.next_tx(BUYER);
    {
        let mut intel = scenario.take_from_address<IntelObject>(CREATOR);
        let ctx = scenario.ctx();
        intel.update_encrypted_key(vector[9, 9, 9], ctx);
        destroy(intel);
    };
    scenario.end();
}

#[test, expected_failure(abort_code = intel_object::EKeyAlreadySet)]
fun update_encrypted_key_twice_aborts() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let mut intel = mint_test_intel(ctx);
        intel.update_encrypted_key(vector[1, 2, 3], ctx);
        intel.update_encrypted_key(vector[4, 5, 6], ctx);
        destroy(intel);
    };
    scenario.end();
}

#[test]
fun list_and_purchase_succeeds() {
    let mut scenario = test_scenario::begin(CREATOR);
    // Creator mints and lists
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);
        marketplace::list(intel, 1_000_000_000, ctx);
    };
    // Buyer purchases
    scenario.next_tx(BUYER);
    {
        let mut listing = scenario.take_shared<Listing>();
        assert!(listing.has_intel());
        assert!(listing.price() == 1_000_000_000);
        assert!(listing.seller() == CREATOR);

        let ctx = scenario.ctx();
        let payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx);
        let intel = marketplace::purchase(&mut listing, payment, ctx);

        // Verify the buyer got the IntelObject
        assert!(*intel.blob_id() == b"blob_abc123".to_string());
        assert!(intel.creator() == CREATOR);

        // Listing is now empty
        assert!(!listing.has_intel());

        transfer::public_transfer(intel, BUYER);
        test_scenario::return_shared(listing);
    };
    scenario.end();
}

#[test, expected_failure(abort_code = marketplace::EWrongPayment)]
fun purchase_wrong_amount_aborts() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);
        marketplace::list(intel, 1_000_000_000, ctx);
    };
    scenario.next_tx(BUYER);
    {
        let mut listing = scenario.take_shared<Listing>();
        let ctx = scenario.ctx();
        let payment = coin::mint_for_testing<SUI>(500_000_000, ctx);
        let intel = marketplace::purchase(&mut listing, payment, ctx);
        destroy(intel);
        test_scenario::return_shared(listing);
    };
    scenario.end();
}

#[test]
fun delist_returns_intel_to_seller() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);
        marketplace::list(intel, 1_000_000_000, ctx);
    };
    scenario.next_tx(CREATOR);
    {
        let mut listing = scenario.take_shared<Listing>();
        assert!(listing.has_intel());
        let ctx = scenario.ctx();
        let intel = marketplace::delist(&mut listing, ctx);
        assert!(!listing.has_intel());
        assert!(*intel.blob_id() == b"blob_abc123".to_string());
        transfer::public_transfer(intel, CREATOR);
        test_scenario::return_shared(listing);
    };
    scenario.end();
}

#[test, expected_failure(abort_code = marketplace::ENotSeller)]
fun delist_wrong_caller_aborts() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);
        marketplace::list(intel, 1_000_000_000, ctx);
    };
    scenario.next_tx(RANDOM);
    {
        let mut listing = scenario.take_shared<Listing>();
        let ctx = scenario.ctx();
        let intel = marketplace::delist(&mut listing, ctx);
        destroy(intel);
        test_scenario::return_shared(listing);
    };
    scenario.end();
}

#[test, expected_failure(abort_code = marketplace::ENoIntel)]
fun purchase_already_sold_aborts() {
    let mut scenario = test_scenario::begin(CREATOR);
    {
        let ctx = scenario.ctx();
        let intel = mint_test_intel(ctx);
        marketplace::list(intel, 1_000_000_000, ctx);
    };
    // First buyer succeeds
    scenario.next_tx(BUYER);
    {
        let mut listing = scenario.take_shared<Listing>();
        let ctx = scenario.ctx();
        let payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx);
        let intel = marketplace::purchase(&mut listing, payment, ctx);
        transfer::public_transfer(intel, BUYER);
        test_scenario::return_shared(listing);
    };
    // Second buyer fails — listing is empty
    scenario.next_tx(RANDOM);
    {
        let mut listing = scenario.take_shared<Listing>();
        let ctx = scenario.ctx();
        let payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx);
        let intel = marketplace::purchase(&mut listing, payment, ctx);
        destroy(intel);
        test_scenario::return_shared(listing);
    };
    scenario.end();
}
