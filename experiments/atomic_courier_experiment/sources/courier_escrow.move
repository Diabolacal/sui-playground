/// Courier Escrow — Economic Contract Feasibility Probe
///
/// Proves on local Sui devnet:
///   - Collateral + reward escrow
///   - Deadline / expiry (using sui::clock)
///   - State machine transitions (Posted → Active → Completed | Expired)
///   - Dispute-free settlement
///   - Cancellation (creator-only, before acceptance)
///
/// IMPORTANT — Game ↔ Chain Boundary:
///   The chain cannot "hold" a physical game item during transit.
///   This contract models ECONOMIC INCENTIVES (escrow, collateral, deadlines),
///   not physical item custody. "Cargo" is represented as a job receipt / claim
///   token, not as a real SSU item persisting during transit.
///
/// This is NOT a production module. It is a minimal feasibility test.
module atomic_courier_experiment::courier_escrow;

use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};
use sui::sui::SUI;
use sui::clock::Clock;
use sui::event;

// === Constants (State) ===

const STATE_POSTED: u8 = 0;
const STATE_ACTIVE: u8 = 1;
const STATE_COMPLETED: u8 = 2;
const STATE_EXPIRED: u8 = 3;
const STATE_CANCELLED: u8 = 4;

// === Error Codes ===

const ENotCreator: u64 = 0;
#[allow(unused_const)]
const ENotCourier: u64 = 1;
const EInvalidState: u64 = 2;
const EDeadlineNotPassed: u64 = 3;
const EDeadlinePassed: u64 = 4;
const EInsufficientCollateral: u64 = 5;

// === Objects ===

/// Shared object representing a courier delivery job.
/// Uses Balance<SUI> for escrow to avoid Coin drop issues.
public struct CourierJob has key {
    id: UID,
    /// Address that posted the job and escrowed the reward.
    creator: address,
    /// Address of the courier who accepted. None until accepted.
    courier: option::Option<address>,
    /// Reward balance escrowed by the creator.
    reward: Balance<SUI>,
    /// Required collateral amount in MIST that the courier must deposit.
    collateral_required: u64,
    /// Collateral balance escrowed by the courier (zero until accepted).
    collateral: Balance<SUI>,
    /// Deadline timestamp in milliseconds (epoch time). After this, the job
    /// can be expired by anyone.
    deadline_ms: u64,
    /// Current state of the job.
    state: u8,
}

/// Receipt token given to the courier upon accepting a job.
/// Can be used as proof-of-assignment if needed in future extensions.
public struct JobReceipt has key, store {
    id: UID,
    job_id: ID,
    courier: address,
}

// === Events ===

public struct JobPostedEvent has copy, drop {
    job_id: ID,
    creator: address,
    reward_amount: u64,
    collateral_required: u64,
    deadline_ms: u64,
}

public struct JobAcceptedEvent has copy, drop {
    job_id: ID,
    courier: address,
    collateral_amount: u64,
}

public struct JobCompletedEvent has copy, drop {
    job_id: ID,
    creator: address,
    courier: address,
    reward_amount: u64,
    collateral_returned: u64,
}

public struct JobExpiredEvent has copy, drop {
    job_id: ID,
    creator: address,
    courier: address,
    collateral_slashed: u64,
    reward_returned: u64,
    caller: address,
}

public struct JobCancelledEvent has copy, drop {
    job_id: ID,
    creator: address,
    reward_returned: u64,
}

// === Entry Functions ===

/// Post a new courier job. The creator escrows a reward coin and specifies
/// the collateral requirement and deadline.
///
/// The CourierJob is shared so any potential courier can read and accept it.
public fun post_job(
    reward: Coin<SUI>,
    collateral_required: u64,
    deadline_ms: u64,
    ctx: &mut TxContext,
): ID {
    let creator = ctx.sender();
    let reward_amount = reward.value();

    let job = CourierJob {
        id: object::new(ctx),
        creator,
        courier: option::none(),
        reward: coin::into_balance(reward),
        collateral_required,
        collateral: balance::zero(),
        deadline_ms,
        state: STATE_POSTED,
    };

    let job_id = object::id(&job);

    event::emit(JobPostedEvent {
        job_id,
        creator,
        reward_amount,
        collateral_required,
        deadline_ms,
    });

    transfer::share_object(job);

    job_id
}

/// Accept a job by depositing the required collateral.
/// Transitions: Posted → Active.
/// Sends a JobReceipt to the courier.
///
/// Requirement: collateral_coin.value() >= job.collateral_required
/// Requirement: deadline must not have passed yet
public fun accept_job(
    job: &mut CourierJob,
    collateral_coin: Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Must be in Posted state
    assert!(job.state == STATE_POSTED, EInvalidState);

    // Deadline must not have passed
    let now = clock.timestamp_ms();
    assert!(now < job.deadline_ms, EDeadlinePassed);

    // Collateral must meet requirement
    assert!(collateral_coin.value() >= job.collateral_required, EInsufficientCollateral);

    let courier = ctx.sender();
    let collateral_amount = collateral_coin.value();

    job.courier = option::some(courier);
    // Merge collateral into the job's collateral balance
    balance::join(&mut job.collateral, coin::into_balance(collateral_coin));
    job.state = STATE_ACTIVE;

    // Create receipt for the courier
    let receipt = JobReceipt {
        id: object::new(ctx),
        job_id: object::id(job),
        courier,
    };

    event::emit(JobAcceptedEvent {
        job_id: object::id(job),
        courier,
        collateral_amount,
    });

    transfer::transfer(receipt, courier);
}

/// Complete a job. Only the creator can confirm delivery in this minimal model.
/// Transitions: Active → Completed.
///
/// Settlement:
///   - Courier receives the escrowed reward
///   - Courier receives their collateral back
public fun complete_job(
    job: &mut CourierJob,
    ctx: &mut TxContext,
) {
    // Must be in Active state
    assert!(job.state == STATE_ACTIVE, EInvalidState);

    // Only creator can confirm delivery
    assert!(ctx.sender() == job.creator, ENotCreator);

    let courier = *option::borrow(&job.courier);
    let reward_amount = balance::value(&job.reward);
    let collateral_returned = balance::value(&job.collateral);

    // Extract reward and send to courier
    let reward_coin = coin::from_balance(
        balance::split(&mut job.reward, reward_amount),
        ctx,
    );
    transfer::public_transfer(reward_coin, courier);

    // Extract collateral and return to courier
    let collateral_coin = coin::from_balance(
        balance::split(&mut job.collateral, collateral_returned),
        ctx,
    );
    transfer::public_transfer(collateral_coin, courier);

    job.state = STATE_COMPLETED;

    event::emit(JobCompletedEvent {
        job_id: object::id(job),
        creator: job.creator,
        courier,
        reward_amount,
        collateral_returned,
    });
}

/// Expire a job after the deadline has passed. Anyone can call this.
/// Transitions: Active → Expired.
///
/// Settlement:
///   - Creator receives the courier's collateral (slashing)
///   - Creator receives their reward back
public fun expire_job(
    job: &mut CourierJob,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Must be in Active state
    assert!(job.state == STATE_ACTIVE, EInvalidState);

    // Deadline must have passed
    let now = clock.timestamp_ms();
    assert!(now >= job.deadline_ms, EDeadlineNotPassed);

    let creator = job.creator;
    let courier = *option::borrow(&job.courier);
    let caller = ctx.sender();

    let collateral_slashed = balance::value(&job.collateral);
    let reward_returned = balance::value(&job.reward);

    // Slash collateral to creator
    let collateral_coin = coin::from_balance(
        balance::split(&mut job.collateral, collateral_slashed),
        ctx,
    );
    transfer::public_transfer(collateral_coin, creator);

    // Return reward to creator
    let reward_coin = coin::from_balance(
        balance::split(&mut job.reward, reward_returned),
        ctx,
    );
    transfer::public_transfer(reward_coin, creator);

    job.state = STATE_EXPIRED;

    event::emit(JobExpiredEvent {
        job_id: object::id(job),
        creator,
        courier,
        collateral_slashed,
        reward_returned,
        caller,
    });
}

/// Cancel a job. Only the creator can cancel, and only before acceptance.
/// Transitions: Posted → Cancelled.
///
/// Settlement:
///   - Creator receives their reward back
public fun cancel_job(
    job: &mut CourierJob,
    ctx: &mut TxContext,
) {
    // Must be in Posted state (not yet accepted)
    assert!(job.state == STATE_POSTED, EInvalidState);

    // Only creator can cancel
    assert!(ctx.sender() == job.creator, ENotCreator);

    let creator = job.creator;
    let reward_returned = balance::value(&job.reward);

    // Return reward to creator
    let reward_coin = coin::from_balance(
        balance::split(&mut job.reward, reward_returned),
        ctx,
    );
    transfer::public_transfer(reward_coin, creator);

    job.state = STATE_CANCELLED;

    event::emit(JobCancelledEvent {
        job_id: object::id(job),
        creator,
        reward_returned,
    });
}

// === View Functions (for testing) ===

public fun state(job: &CourierJob): u8 { job.state }
public fun creator(job: &CourierJob): address { job.creator }
public fun courier(job: &CourierJob): &option::Option<address> { &job.courier }
public fun reward_value(job: &CourierJob): u64 { balance::value(&job.reward) }
public fun collateral_value(job: &CourierJob): u64 { balance::value(&job.collateral) }
public fun collateral_required(job: &CourierJob): u64 { job.collateral_required }
public fun deadline_ms(job: &CourierJob): u64 { job.deadline_ms }
