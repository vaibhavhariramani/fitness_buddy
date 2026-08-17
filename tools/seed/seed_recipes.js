// One-time local script to seed the public-read `recipes` collection.
// Not part of the deployed app — run manually from your machine once.
//
// Setup:
//   npm install firebase-admin
//   Download a service account key (Firebase console > Project settings >
//   Service accounts > Generate new private key) and save it as
//   tools/seed/service-account.json (already gitignored).
//
// Run:
//   node tools/seed/seed_recipes.js

const admin = require('firebase-admin');
const recipes = require('./recipes.json');
const serviceAccount = require('./service-account.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function main() {
  const batch = db.batch();
  for (const recipe of recipes) {
    const ref = db.collection('recipes').doc();
    batch.set(ref, recipe);
  }
  await batch.commit();
  console.log(`Seeded ${recipes.length} recipes.`);
}

main().then(() => process.exit(0)).catch((err) => {
  console.error(err);
  process.exit(1);
});
