/// Marketplace — listing and purchase logic for IntelObjects.
/// Listings are shared objects so any buyer can purchase atomically.
module shadow_broker::marketplace;

use sui::coin::Coin;
use sui::sui::SUI;
use sui::event;
use shadow_broker::intel_object::IntelObject;

// === Errors ===

#[error]
const EWrongPayment: vector<u8> = b"Payment does not match listing price";

#[error]
const ENotSeller: vector<u8> = b"Only the seller can delist";

#[error]
const ENoIntel: vector<u8> = b"Listing has already been purchased";

// === Structs ===

/// A marketplace listing wrapping an IntelObject.
/// Shared object so any buyer can purchase.
public struct Listing has key {
    id: UID,
    intel: Option<IntelObject>,
    price: u64,
    seller: address,
}

// === Events ===

public struct ListingCreatedEvent has copy, drop {
    listing_id: address,
    seller: address,
    price: u64,
}

public struct PurchaseEvent has copy, drop {
    listing_id: address,
    buyer: address,
    seller: address,
    price: u64,
}

// === Public Functions ===

/// Seller lists an IntelObject for sale. Creates a shared Listing.
public fun list(
    intel: IntelObject,
    price: u64,
    ctx: &mut TxContext,
) {
    let seller = ctx.sender();
    let listing = Listing {
        id: object::new(ctx),
        intel: option::some(intel),
        price,
        seller,
    };
    event::emit(ListingCreatedEvent {
        listing_id: listing.id.to_address(),
        seller,
        price,
    });
    transfer::share_object(listing);
}

/// Buyer purchases a listing. Atomic: coin to seller, IntelObject to buyer.
/// Caller must pass exact Coin<SUI> matching listing price.
public fun purchase(
    listing: &mut Listing,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
): IntelObject {
    assert!(payment.value() == listing.price, EWrongPayment);
    assert!(listing.intel.is_some(), ENoIntel);
    transfer::public_transfer(payment, listing.seller);
    event::emit(PurchaseEvent {
        listing_id: listing.id.to_address(),
        buyer: ctx.sender(),
        seller: listing.seller,
        price: listing.price,
    });
    listing.intel.extract()
}

/// Seller reclaims an unsold IntelObject.
public fun delist(
    listing: &mut Listing,
    ctx: &TxContext,
): IntelObject {
    assert!(ctx.sender() == listing.seller, ENotSeller);
    assert!(listing.intel.is_some(), ENoIntel);
    listing.intel.extract()
}

// === View Functions ===

public fun price(self: &Listing): u64 { self.price }
public fun seller(self: &Listing): address { self.seller }
public fun has_intel(self: &Listing): bool { self.intel.is_some() }
