/// Atomic Courier Experiment — Feasibility Probe
///
/// Tests whether withdraw_item + deposit_item + coin transfer can execute
/// atomically in a single transaction across two different StorageUnit objects.
///
/// This is NOT a production module. It is a minimal composition test.
module atomic_courier_experiment::atomic_transfer;

use sui::coin::Coin;
use sui::sui::SUI;
use sui::event;
use world::storage_unit::StorageUnit;
use world::character::Character;
use atomic_courier_experiment::config;

// === Events ===

/// Emitted on successful atomic transfer to prove composition worked.
public struct AtomicTransferEvent has copy, drop {
    source_ssu_id: ID,
    dest_ssu_id: ID,
    character_id: ID,
    item_type_id: u64,
    reward_amount: u64,
    courier: address,
}

// === Core Test Function ===

/// Atomically:
/// 1. Withdraws item from source SSU
/// 2. Deposits item into destination SSU
/// 3. Transfers reward coin to courier (tx sender)
///
/// Both SSUs must have this package's XAuth extension authorized.
/// No AdminACL needed — extension-based access only.
public fun atomic_transfer_test(
    source_ssu: &mut StorageUnit,
    dest_ssu: &mut StorageUnit,
    character: &Character,
    item_type_id: u64,
    reward_coin: Coin<SUI>,
    ctx: &mut TxContext,
) {
    let source_ssu_id = object::id(source_ssu);
    let dest_ssu_id = object::id(dest_ssu);
    let character_id = object::id(character);
    let courier = ctx.sender();
    let reward_amount = reward_coin.value();

    // Step 1: Withdraw item from source SSU (consumes one XAuth witness)
    let item = world::storage_unit::withdraw_item(
        source_ssu,
        character,
        config::x_auth(),
        item_type_id,
        ctx,
    );

    // Step 2: Deposit item into destination SSU (consumes another XAuth witness)
    world::storage_unit::deposit_item(
        dest_ssu,
        character,
        item,
        config::x_auth(),
        ctx,
    );

    // Step 3: Transfer reward to courier
    transfer::public_transfer(reward_coin, courier);

    // Emit proof event
    event::emit(AtomicTransferEvent {
        source_ssu_id,
        dest_ssu_id,
        character_id,
        item_type_id,
        reward_amount,
        courier,
    });
}
