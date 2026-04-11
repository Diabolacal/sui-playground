/// IntelObject — NFT representing a piece of encrypted intelligence.
/// Holds a Walrus blob reference and a Seal-encrypted AES key.
/// Ownership gates decryption via the `seal_approve` entry function.
module shadow_broker::intel_object;

use std::string::String;
use sui::event;

// === Errors ===

#[error]
const ENotCreator: vector<u8> = b"Caller does not own this IntelObject";

#[error]
const EKeyAlreadySet: vector<u8> = b"Encrypted key can only be set once";

// === Structs ===

/// The NFT representing a piece of encrypted intelligence.
public struct IntelObject has key, store {
    id: UID,
    blob_id: String,
    encrypted_key: vector<u8>,
    file_type: String,
    duration_seconds: u64,
    file_size_bytes: u64,
    description: String,
    creator: address,
    teaser_blob_id: Option<String>,
}

// === Events ===

public struct IntelMintedEvent has copy, drop {
    intel_id: address,
    blob_id: String,
    creator: address,
    has_teaser: bool,
}

// === Public Functions ===

/// Mint a new IntelObject. Returns the object (composable — caller transfers or wraps).
/// The `encrypted_key` is typically empty at mint time; set via `update_encrypted_key`
/// after Seal encryption completes client-side.
public fun mint(
    blob_id: String,
    encrypted_key: vector<u8>,
    file_type: String,
    duration_seconds: u64,
    file_size_bytes: u64,
    description: String,
    teaser_blob_id: Option<String>,
    ctx: &mut TxContext,
): IntelObject {
    let intel = IntelObject {
        id: object::new(ctx),
        blob_id,
        encrypted_key,
        file_type,
        duration_seconds,
        file_size_bytes,
        description,
        creator: ctx.sender(),
        teaser_blob_id,
    };
    event::emit(IntelMintedEvent {
        intel_id: intel.id.to_address(),
        blob_id: intel.blob_id,
        creator: intel.creator,
        has_teaser: intel.teaser_blob_id.is_some(),
    });
    intel
}

/// Update the encrypted key after Seal encryption. Creator-only, one-time.
public fun update_encrypted_key(
    self: &mut IntelObject,
    encrypted_key: vector<u8>,
    ctx: &TxContext,
) {
    assert!(ctx.sender() == self.creator, ENotCreator);
    assert!(self.encrypted_key.is_empty(), EKeyAlreadySet);
    self.encrypted_key = encrypted_key;
}

// === Seal Access Policy ===

/// Seal calls this to verify the caller is authorized to decrypt.
/// The `id` parameter encodes the IntelObject's Sui object address.
/// Seal key servers call this function in a dry-run PTB to verify access.
entry fun seal_approve(id: vector<u8>, self: &IntelObject, _ctx: &TxContext) {
    let parsed_id = object::id_from_bytes(id);
    assert!(parsed_id == object::id(self), ENotCreator);
}

// === View Functions ===

public fun blob_id(self: &IntelObject): &String { &self.blob_id }
public fun encrypted_key(self: &IntelObject): &vector<u8> { &self.encrypted_key }
public fun file_type(self: &IntelObject): &String { &self.file_type }
public fun duration_seconds(self: &IntelObject): u64 { self.duration_seconds }
public fun file_size_bytes(self: &IntelObject): u64 { self.file_size_bytes }
public fun description(self: &IntelObject): &String { &self.description }
public fun creator(self: &IntelObject): address { self.creator }
public fun teaser_blob_id(self: &IntelObject): &Option<String> { &self.teaser_blob_id }
