/// SSU-Backed TradePost — Extension Witness Storefront Validation
///
/// PURPOSE: Validate the SSU-backed storefront pattern where:
/// - Items remain in the SSU (not embedded in the Listing)
/// - buy() uses a TradeAuth witness to call mock_ssu::withdraw_item<TradeAuth>()
/// - The buyer's single-signed PTB atomically:
///   1. Splits coin for payment
///   2. Withdraws item from SSU (via extension witness — no OwnerCap needed)
///   3. Transfers item to buyer
///   4. Transfers payment to seller
///   5. Marks listing inactive
///
/// CRITICAL DESIGN:
/// - TradeAuth is defined HERE (in this module), not in mock_ssu
/// - mock_ssu::authorize_extension<TradeAuth>() registers THIS module's witness
/// - mock_ssu::withdraw_item<TradeAuth>() verifies the type matches
/// - Only THIS module can create TradeAuth {} instances (Move module system)
/// - This is the EXACT same cross-module witness pattern used in world-contracts
///
/// Mirrors the recommended "Option A" from:
///   docs/architecture/tradepost-cross-address-ptb-validation.md
///
/// THIS IS SANDBOX CODE — validates Sui-level mechanics only.
#[allow(unused_use)]
module trade_post_validation::ssu_trade {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use trade_post_validation::mock_ssu::{Self, StorageUnit, OwnerCap};

    // ========== Error Codes ==========

    const ENotSeller: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const EListingNotActive: u64 = 2;
    const EWrongSSU: u64 = 3;

    // ========== Witness Type ==========

    /// The extension witness type. Only this module can create TradeAuth {}.
    /// When registered on an SSU via authorize_extension<TradeAuth>(),
    /// only this module's buy() function can withdraw items.
    public struct TradeAuth has drop {}

    // ========== Types ==========

    /// SSU-backed listing. KEY DIFFERENCE from escrow Listing:
    /// - NO `item: Option<Item>` field — item stays in the SSU
    /// - Instead stores `ssu_id` + `item_type_id` as a reference
    /// - The listing is a "claim ticket" — buy() pulls the item from the SSU
    public struct Listing has key {
        id: UID,
        seller: address,
        price: u64,
        item_type_id: u64,
        ssu_id: ID,
        is_active: bool,
    }

    // ========== Events ==========

    public struct ListingCreated has copy, drop {
        listing_id: address,
        seller: address,
        ssu_id: address,
        price: u64,
        item_type_id: u64,
    }

    public struct ItemPurchased has copy, drop {
        listing_id: address,
        ssu_id: address,
        buyer: address,
        seller: address,
        price: u64,
        item_id: address,
    }

    public struct ListingCancelled has copy, drop {
        listing_id: address,
        seller: address,
    }

    // ========== Setup Functions (Seller) ==========

    /// Convenience: create SSU, share it, return OwnerCap to caller.
    /// Wraps mock_ssu::create_storage_unit + share.
    public fun setup_storefront(ctx: &mut TxContext): OwnerCap {
        let (ssu, cap) = mock_ssu::create_storage_unit(ctx);
        mock_ssu::share_storage_unit(ssu);
        cap
    }

    /// Authorize THIS module's TradeAuth witness on an SSU.
    /// Must be called by the SSU owner (OwnerCap holder).
    /// After this, buy() can withdraw items from this SSU.
    public fun authorize_trade_extension(
        ssu: &mut StorageUnit,
        owner_cap: &OwnerCap,
    ) {
        mock_ssu::authorize_extension<TradeAuth>(ssu, owner_cap);
    }

    /// Mint and deposit an item into the SSU in one call.
    public fun stock_item(
        ssu: &mut StorageUnit,
        owner_cap: &OwnerCap,
        type_id: u64,
        name: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let item = mock_ssu::mint_item(type_id, name, ctx);
        mock_ssu::deposit_item(ssu, owner_cap, item);
    }

    // ========== Listing Functions ==========

    /// Create an SSU-backed listing. Item stays in the SSU.
    /// The listing references (ssu_id, item_type_id) — it's a claim ticket.
    public fun create_listing(
        ssu: &StorageUnit,
        owner_cap: &OwnerCap,
        item_type_id: u64,
        price: u64,
        ctx: &mut TxContext,
    ) {
        // Verify caller owns this SSU
        assert!(mock_ssu::owner_cap_ssu_id(owner_cap) == object::id(ssu), ENotSeller);

        let listing = Listing {
            id: object::new(ctx),
            seller: ctx.sender(),
            price,
            item_type_id,
            ssu_id: object::id(ssu),
            is_active: true,
        };

        event::emit(ListingCreated {
            listing_id: object::id_address(&listing),
            seller: ctx.sender(),
            ssu_id: object::id_address(ssu),
            price,
            item_type_id,
        });

        transfer::share_object(listing);
    }

    // ========== Buy Function (Buyer) ==========

    /// Atomic SSU-backed buy. This is the KEY validation target.
    ///
    /// In a single buyer-signed PTB:
    /// 1. buyer splits coin → payment
    /// 2. buyer calls buy(listing, ssu, payment)
    ///    a. Listing validated (active, correct SSU)
    ///    b. Payment validated (sufficient)
    ///    c. withdraw_item<TradeAuth>(ssu, TradeAuth{}, type_id) — witness-gated!
    ///    d. Item transferred to buyer
    ///    e. Payment transferred to seller
    ///    f. Listing marked inactive
    ///
    /// The buyer NEVER needs the seller's OwnerCap. The TradeAuth witness
    /// is created internally by this module. The SSU's extension check
    /// (type_name::get<TradeAuth>() must match registered extension)
    /// guarantees only this module can withdraw.
    public fun buy(
        listing: &mut Listing,
        ssu: &mut StorageUnit,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        // Validate listing
        assert!(listing.is_active, EListingNotActive);
        assert!(listing.ssu_id == object::id(ssu), EWrongSSU);

        // Validate payment
        assert!(coin::value(&payment) >= listing.price, EInsufficientPayment);

        // === THE CRITICAL EXTENSION CALL ===
        // withdraw_item<TradeAuth> verifies:
        //   1. SSU has an extension registered
        //   2. Registered extension type == type_name::get<TradeAuth>()
        // Only this module can create TradeAuth {} (Move's module system).
        // No OwnerCap needed — the witness IS the authorization.
        let item = mock_ssu::withdraw_item<TradeAuth>(
            ssu,
            TradeAuth {},
            listing.item_type_id,
        );
        let item_id = object::id_address(&item);

        // Transfer item to buyer
        transfer::public_transfer(item, ctx.sender());

        // Transfer payment to seller
        transfer::public_transfer(payment, listing.seller);

        // Mark listing sold
        listing.is_active = false;

        event::emit(ItemPurchased {
            listing_id: object::id_address(listing),
            ssu_id: object::id_address(ssu),
            buyer: ctx.sender(),
            seller: listing.seller,
            price: listing.price,
            item_id,
        });
    }

    /// Cancel a listing. Only the seller can cancel.
    /// Item stays in the SSU (since it was never removed).
    public fun cancel_listing(
        listing: &mut Listing,
        ctx: &mut TxContext,
    ) {
        assert!(ctx.sender() == listing.seller, ENotSeller);
        assert!(listing.is_active, EListingNotActive);
        listing.is_active = false;

        event::emit(ListingCancelled {
            listing_id: object::id_address(listing),
            seller: listing.seller,
        });
    }

    // ========== View Functions ==========

    public fun listing_price(listing: &Listing): u64 { listing.price }
    public fun listing_seller(listing: &Listing): address { listing.seller }
    public fun listing_is_active(listing: &Listing): bool { listing.is_active }
    public fun listing_ssu_id(listing: &Listing): ID { listing.ssu_id }
    public fun listing_item_type_id(listing: &Listing): u64 { listing.item_type_id }
}
