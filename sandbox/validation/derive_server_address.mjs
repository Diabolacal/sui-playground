// derive_server_address.mjs
// Usage: NODE_PATH=/tmp/node_modules node derive_server_address.mjs <privkey_hex>
import { blake2b } from '@noble/hashes/blake2.js';
import crypto from 'crypto';

const privkeyHex = process.argv[2];
const pk = Buffer.from(privkeyHex, 'hex');
const key = crypto.createPrivateKey({
  key: Buffer.concat([Buffer.from('302e020100300506032b657004220420','hex'), pk]),
  format:'der', type:'pkcs8'
});
const pub = crypto.createPublicKey(key).export({type:'spki',format:'der'}).slice(-32);
const addr = Buffer.from(blake2b(Buffer.concat([Buffer.from([0x00]), pub]), {dkLen:32}));
console.log('0x' + addr.toString('hex'));
