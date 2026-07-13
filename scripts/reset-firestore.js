// Wipes the old Flutter-era data out of the existing "chs-crm" Firebase
// project so the new Electron/React build starts clean WITHIN the same
// project (same project id, same billing/free-tier status — nothing new to
// set up in Firebase itself).
//
// Requires a service account key:
//   Firebase Console > Project Settings > Service Accounts > Generate new
//   private key. Save it as scripts/firebase-admin-key.json — it's already
//   gitignored, never commit it.
//
// Usage:
//   node scripts/reset-firestore.js --confirm
//
// Deliberately requires --confirm so this can't be run by accident. Deletes
// the "properties" and "users" collections. Leaves "documentCategories"
// alone since that's new to this rebuild, not old Flutter data.

const admin = require('firebase-admin');
const path = require('path');

const CONFIRM = process.argv.includes('--confirm');
const COLLECTIONS_TO_WIPE = ['properties', 'users'];

if (!CONFIRM) {
  console.log('This will permanently delete all documents in:', COLLECTIONS_TO_WIPE.join(', '));
  console.log('Re-run with --confirm to actually do it:');
  console.log('  node scripts/reset-firestore.js --confirm');
  process.exit(0);
}

const keyPath = path.join(__dirname, 'firebase-admin-key.json');
let serviceAccount;
try {
  serviceAccount = require(keyPath);
} catch (err) {
  console.error(
    `Couldn't find scripts/firebase-admin-key.json. Download it from ` +
      `Firebase Console > Project Settings > Service Accounts > Generate new private key, ` +
      `and save it at that path.`
  );
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function wipeCollection(name) {
  const snap = await db.collection(name).get();
  if (snap.empty) {
    console.log(`  ${name}: already empty`);
    return;
  }
  const batchSize = 400;
  const docs = snap.docs;
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = db.batch();
    docs.slice(i, i + batchSize).forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
  console.log(`  ${name}: deleted ${docs.length} documents`);
}

(async () => {
  console.log('Resetting Firestore data in project:', serviceAccount.project_id);
  for (const name of COLLECTIONS_TO_WIPE) {
    await wipeCollection(name);
  }
  console.log('Done. documentCategories was left alone — the app seeds it fresh on first run.');
  process.exit(0);
})();
