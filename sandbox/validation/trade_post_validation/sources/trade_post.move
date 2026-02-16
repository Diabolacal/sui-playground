/// TradePost Cross-Address Validation Module
///
/// PURPOSE: Validate that a buyer (address B) can atomically purchase an item
/// from a seller (address A) using a shared Listing object + Coin transfer,
/// in a single buyer-signed PTB.
///
/// THIS IS SANDBOX CODE — DO NOT COPY TO HACKATHON SUBMISSION.
/// Reimplement from scratch on March 11 using world-contracts extension pattern.
///
/// What this validates:
/// 1. Shared Listing object is accessible by any address
/// 2. Coin<SUI> transfer from buyer to seller works atomically
/// 3. Item object transfer from listing to buyer works atomically
/// 4. All three operations compose in a single PTB
///
/// What this does NOT validate (deferred to hackathon):
/// - SSU extension-based withdraw_item<Auth> (requires world-contracts dependency)
/// - AdminACL sponsored transactions
/// - Character/tribe mechanics
///
/// The world-contracts unit tests already prove extension-based cross-address
/// withdrawal works (test_swap_ammo_for_lens in storage_unit_tests.move L736).
/// This module validates the Sui-level PTB composition mechanics.
module trade_post_validation::trade_post {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;

    // ========== Error Codes ==========

    const ENotSeller: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const EListingNotActive: u64 = 2;

    // ========== Types ==========

    /// Represents a tradeable item. In the real system, items are dynamic fields
    /// on StorageUnit inventories. Here we use a standalone object for simplicity.
    public struct Item has key, store {
        id: UID,
        type_id: u64,
        name: vector<u8>,
    }

    /// A shared listing object. Anyone can read it; only the buy() function
    /// modifies it (by consuming the item and marking it sold).
    public struct Listing has key {
        id: UID,
        seller: address,
        price: u64,
        item_type_id: u64,
        item_name: vector<u8>,
        is_active: bool,
        // The item is stored inside the listing as an Option.
        // In the real system, the item would be in an SSU inventory
        // and withdrawn via extension auth during buy().
        item: Option<Item>,
    }

    // ========== Events ==========

    public struct ItemMinted has copy, drop {
        item_id: address,
        type_id: u64,
        owner: address,
    }

    public struct ListingCreated has copy, drop {
        listing_id: address,
        seller: address,
        price: u64,
        item_type_id: u64,
    }

    public struct ItemPurchased has copy, drop {
        listing_id: address,
        buyer: address,
        seller: address,
        price: u64,
        item_id: address,
    }

    // ========== Seller Functions ==========

    /// Mint a test item. In the real system, items come from the game world.
    public fun mint_item(
        type_id: u64,
        name: vector<u8>,
        ctx: &mut TxContext,
    ): Item {
        let item = Item {
            id: object::new(ctx),
            type_id,
            name,
        };
        event::emit(ItemMinted {
            item_id: object::id_address(&item),
            type_id,
            owner: ctx.sender(),
        });
        item
    }

    /// Seller creates a listing with an item and a price.
    /// The listing is a SHARED object — accessible by any address.
    public fun create_listing(
        item: Item,
        price: u64,
        ctx: &mut TxContext,
    ) {
        let item_type_id = item.type_id;
        let item_name = item.name;
        let seller = ctx.sender();

        let listing = Listing {
            id: object::new(ctx),
            seller,
            price,
            item_type_id,
            item_name,
            is_active: true,
            item: option::some(item),
        };

        event::emit(ListingCreated {
            listing_id: object::id_address(&listing),
            seller,
            price,
            item_type_id,
        });

        // CRITICAL: share the listing so any address can interact with it
        transfer::share_object(listing);
    }

    // ========== Buyer Functions ==========

    /// Buyer atomically purchases an item from a listing.
    ///
    /// This is the CRITICAL cross-address operation:
    /// - Listing is a shared object (accessible by buyer)
    /// - Buyer provides their Coin<SUI> (owned object, accessible by buyer)
    /// - Item is extracted from listing and transferred to buyer
    /// - Payment is transferred to seller
    ///
    /// In a single buyer-signed PTB, this achieves:
    /// 1. Payment: buyer → seller
    /// 2. Item: listing → buyer
    /// 3. State: listing marked inactive
    public fun buy(
        listing: &mut Listing,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        // Validate listing is active
        assert!(listing.is_active, EListingNotActive);

        // Validate payment is sufficient
        assert!(coin::value(&payment) >= listing.price, EInsufficientPayment);

        // Extract item from listing
        let item = listing.item.extract();
        let item_id = object::id_address(&item);

        // Transfer payment to seller
        transfer::public_transfer(payment, listing.seller);

        // Transfer item to buyer
        transfer::public_transfer(item, ctx.sender());

        // Mark listing as sold
        listing.is_active = false;

        // Emit purchase event
        event::emit(ItemPurchased {
            listing_id: object::id_address(listing),
            buyer: ctx.sender(),
            seller: listing.seller,
            price: listing.price,
            item_id,
        });
    }

    // ========== Seller Management ==========

    /// Seller cancels a listing and reclaims the item.
    public fun cancel_listing(
        listing: &mut Listing,
        ctx: &mut TxContext,
    ) {
        assert!(ctx.sender() == listing.seller, ENotSeller);
        assert!(listing.is_active, EListingNotActive);

        let item = listing.item.extract();
        transfer::public_transfer(item, listing.seller);
        listing.is_active = false;
    }

    // ========== View Functions ==========

    public fun listing_price(listing: &Listing): u64 { listing.price }
    public fun listing_seller(listing: &Listing): address { listing.seller }
    public fun listing_is_active(listing: &Listing): bool { listing.is_active }
    public fun item_type_id(item: &Item): u64 { item.type_id }
}
