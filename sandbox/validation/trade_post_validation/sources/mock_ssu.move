/// Mock Smart Storage Unit (SSU) — Extension Pattern Validation
///
/// PURPOSE: Faithfully reproduce the world::storage_unit extension pattern
/// (authorize_extension<Auth>, withdraw_item<Auth>, deposit_item) as a
/// standalone module so that a SEPARATE module (ssu_trade.move) can exercise
/// the cross-module witness-gated withdrawal that drives a storefront buy.
///
/// KEY INVARIANT: withdraw_item<Auth> does NOT require an OwnerCap.
/// It only requires a witness instance of type Auth — which the SSU verifies
/// against its registered extension TypeName. Only the package that defines
/// Auth can create an instance, so access is restricted to the extension module.
///
/// This mirrors:
///   vendor/world-contracts/contracts/world/sources/assemblies/storage_unit.move
///   specifically: authorize_extension<Auth>, withdraw_item<Auth>, deposit_item<Auth>
///
/// THIS IS SANDBOX CODE — validates Sui-level mechanics only.
module trade_post_validation::mock_ssu {
    use std::type_name::{Self, TypeName};
    use sui::event;

    // ========== Error Codes ==========

    const ENotOwner: u64 = 0;
    const EExtensionNotAuthorized: u64 = 1;
    const EWrongExtension: u64 = 2;
    const EItemNotFound: u64 = 3;
    const ESSUEmpty: u64 = 4;

    // ========== Types ==========

    /// Mirrors world::storage_unit::StorageUnit.
    /// Key field: `extension: Option<TypeName>` — single extension slot.
    /// Items stored in a vector (real SSU uses dynamic-field Inventory).
    public struct StorageUnit has key {
        id: UID,
        owner: address,
        extension: Option<TypeName>,
        items: vector<Item>,
    }

    /// Mirrors world::access_control::OwnerCap<StorageUnit>.
    /// Bound to a specific SSU by its ID.
    public struct OwnerCap has key, store {
        id: UID,
        storage_unit_id: ID,
    }

    /// Mirrors world::inventory::Item (key + store abilities).
    public struct Item has key, store {
        id: UID,
        type_id: u64,
        name: vector<u8>,
    }

    // ========== Events ==========

    public struct SSUCreated has copy, drop {
        ssu_id: address,
        owner: address,
    }

    public struct ExtensionAuthorized has copy, drop {
        ssu_id: address,
        extension_type: TypeName,
    }

    public struct ItemDeposited has copy, drop {
        ssu_id: address,
        item_id: address,
        type_id: u64,
    }

    public struct ItemWithdrawn has copy, drop {
        ssu_id: address,
        item_id: address,
        type_id: u64,
        extension_type: TypeName,
    }

    // ========== SSU Lifecycle ==========

    /// Create an SSU and its OwnerCap. Caller shares the SSU afterwards.
    public fun create_storage_unit(ctx: &mut TxContext): (StorageUnit, OwnerCap) {
        let ssu = StorageUnit {
            id: object::new(ctx),
            owner: ctx.sender(),
            extension: option::none(),
            items: vector::empty(),
        };
        let cap = OwnerCap {
            id: object::new(ctx),
            storage_unit_id: object::id(&ssu),
        };
        event::emit(SSUCreated {
            ssu_id: object::id_address(&ssu),
            owner: ctx.sender(),
        });
        (ssu, cap)
    }

    /// Share the SSU so any address can interact with it via extensions.
    public fun share_storage_unit(ssu: StorageUnit) {
        transfer::share_object(ssu);
    }

    // ========== Extension Authorization ==========

    /// Mirrors world::storage_unit::authorize_extension<Auth: drop>.
    ///
    /// Records type_name::get<Auth>() in the SSU's extension slot.
    /// Only the OwnerCap holder can authorize. Only one extension at a time.
    /// Calling again replaces the previous extension.
    public fun authorize_extension<Auth: drop>(
        ssu: &mut StorageUnit,
        owner_cap: &OwnerCap,
    ) {
        assert!(owner_cap.storage_unit_id == object::id(ssu), ENotOwner);
        let auth_type = type_name::with_defining_ids<Auth>();
        ssu.extension.swap_or_fill(auth_type);
        event::emit(ExtensionAuthorized {
            ssu_id: object::id_address(ssu),
            extension_type: type_name::with_defining_ids<Auth>(),
        });
    }

    // ========== Item Operations ==========

    /// Mint a test item. In the real system, items come from the game world.
    public fun mint_item(
        type_id: u64,
        name: vector<u8>,
        ctx: &mut TxContext,
    ): Item {
        Item {
            id: object::new(ctx),
            type_id,
            name,
        }
    }

    /// Owner deposits an item into the SSU (requires OwnerCap).
    public fun deposit_item(
        ssu: &mut StorageUnit,
        owner_cap: &OwnerCap,
        item: Item,
    ) {
        assert!(owner_cap.storage_unit_id == object::id(ssu), ENotOwner);
        event::emit(ItemDeposited {
            ssu_id: object::id_address(ssu),
            item_id: object::id_address(&item),
            type_id: item.type_id,
        });
        ssu.items.push_back(item);
    }

    /// Extension-gated item withdrawal.
    /// Mirrors world::storage_unit::withdraw_item<Auth: drop>.
    ///
    /// KEY: Does NOT require OwnerCap. Requires only the Auth witness instance.
    /// The SSU verifies that type_name::get<Auth>() matches its registered
    /// extension. Since only the defining module can create Auth {}, this
    /// restricts withdrawal to the authorized extension module — even when
    /// called by a completely different address (the buyer).
    public fun withdraw_item<Auth: drop>(
        ssu: &mut StorageUnit,
        _witness: Auth,
        type_id: u64,
    ): Item {
        // Verify extension is authorized
        assert!(ssu.extension.is_some(), EExtensionNotAuthorized);
        let registered = ssu.extension.borrow();
        assert!(*registered == type_name::with_defining_ids<Auth>(), EWrongExtension);

        // Find and remove item by type_id
        let len = ssu.items.length();
        assert!(len > 0, ESSUEmpty);
        let mut i = 0;
        let mut found_idx = len; // sentinel
        while (i < len) {
            if (ssu.items[i].type_id == type_id) {
                found_idx = i;
                break
            };
            i = i + 1;
        };
        assert!(found_idx < len, EItemNotFound);

        let item = ssu.items.swap_remove(found_idx);
        event::emit(ItemWithdrawn {
            ssu_id: object::id_address(ssu),
            item_id: object::id_address(&item),
            type_id: item.type_id,
            extension_type: type_name::with_defining_ids<Auth>(),
        });
        item
    }

    // ========== View Functions ==========

    public fun ssu_owner(ssu: &StorageUnit): address { ssu.owner }
    public fun ssu_extension(ssu: &StorageUnit): &Option<TypeName> { &ssu.extension }
    public fun ssu_item_count(ssu: &StorageUnit): u64 { ssu.items.length() }
    public fun item_type_id(item: &Item): u64 { item.type_id }
    public fun owner_cap_ssu_id(cap: &OwnerCap): ID { cap.storage_unit_id }
}
