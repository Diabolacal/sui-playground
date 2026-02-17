// Check blake2 exports
import('@noble/hashes/blake2.js').then(m => {
  console.log('Exports:', Object.keys(m));
}).catch(e => console.error(e.message));
