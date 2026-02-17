const crypto = require('crypto');

// Check ed25519 support
try {
  const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519');
  const testMsg = Buffer.from('test');
  const sig = crypto.sign(null, testMsg, privateKey);
  const ok = crypto.verify(null, testMsg, publicKey, sig);
  console.log('ed25519: YES (sign/verify works)');
} catch (e) {
  console.log('ed25519: NO -', e.message);
}

// Check blake2b256
try {
  const h = crypto.createHash('blake2b256');
  h.update(Buffer.from('test'));
  console.log('blake2b256:', h.digest('hex'));
} catch (e) {
  console.log('blake2b256 direct: NO -', e.message);
}

// Check blake2b512 
try {
  const h = crypto.createHash('blake2b512');
  h.update(Buffer.from('test'));
  console.log('blake2b512:', h.digest('hex').substring(0, 16) + '...');
} catch (e) {
  console.log('blake2b512: NO');
}

// Node.js 24 might have blake2b with options
try {
  const { blake2b256 } = require('crypto');
  console.log('blake2b256 named export: YES');
} catch (e) {
  // Try hash with options
  console.log('No named blake2b256 export');
}

console.log('Node version:', process.version);
console.log('OpenSSL version:', crypto.constants ? 'available' : 'not');
console.log('Available hashes:', crypto.getHashes().filter(h => h.includes('blake')).join(', '));
