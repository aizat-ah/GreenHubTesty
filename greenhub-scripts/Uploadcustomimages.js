/**
 * GreenHub Custom Image Uploader
 * ---------------------------------
 * Uploads your manually-curated local images (e.g. bawang-merah.jpg,
 * kacang-buncis.jpg) to Firebase Storage, then updates the matching
 * product's imageUrl field in Firestore.
 *
 * MATCHING LOGIC:
 * Filename (minus extension) is converted from kebab-case to a name key
 * ("bawang-merah" -> "bawang merah") and matched against product names
 * in Firestore (case-insensitive). A fallback pass also tries matching
 * with all spaces removed, to handle things like "cendawan-portobello"
 * vs "Cendawan Portobello" reliably.
 *
 * SETUP:
 * 1. Put all your renamed images into a folder called `custom-images`
 *    inside this same greenhub-scripts folder.
 * 2. Find your Storage bucket name: Firebase Console > Storage — it's
 *    shown at the top as "gs://your-bucket-name". Paste it into
 *    BUCKET_NAME below (without the "gs://" prefix).
 * 3. Run: node uploadCustomImages.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./serviceAccountKey.json');

// TODO: paste your actual bucket name here (Firebase Console > Storage)
const BUCKET_NAME = 'greenhub-315c0.firebasestorage.app';

// Folder containing your custom images
const IMAGES_FOLDER = './custom-images';

initializeApp({
  credential: cert(serviceAccount),
  storageBucket: BUCKET_NAME,
});

const db = getFirestore();
const bucket = getStorage().bucket();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function normalizeKey(name) {
  return name.trim().toLowerCase().replace(/\s+/g, ' ');
}

function collapseKey(name) {
  return normalizeKey(name).replace(/\s+/g, '');
}

function slugToKey(filename) {
  const base = path.parse(filename).name; // strip extension
  return normalizeKey(base.replace(/-/g, ' '));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function run() {
  if (!fs.existsSync(IMAGES_FOLDER)) {
    console.error(`Folder not found: ${IMAGES_FOLDER}. Create it and add your images first.`);
    process.exit(1);
  }

  const files = fs
    .readdirSync(IMAGES_FOLDER)
    .filter((f) => /\.(jpe?g|png|webp)$/i.test(f));

  console.log(`Found ${files.length} image files in ${IMAGES_FOLDER}\n`);

  const snapshot = await db.collection('products').get();

  const byExactKey = new Map();
  const byCollapsedKey = new Map();

  snapshot.forEach((doc) => {
    const name = doc.data().name || '';
    byExactKey.set(normalizeKey(name), doc);
    byCollapsedKey.set(collapseKey(name), doc);
  });

  let updated = 0;
  let notMatched = 0;

  for (const file of files) {
    const key = slugToKey(file);
    const doc = byExactKey.get(key) || byCollapsedKey.get(collapseKey(key));

    if (!doc) {
      console.log(`NO MATCH  "${file}" — no product found named "${key}"`);
      notMatched++;
      continue;
    }

    const product = doc.data();
    const localPath = path.join(IMAGES_FOLDER, file);
    const destination = `products/${doc.id}${path.extname(file).toLowerCase()}`;

    try {
      await bucket.upload(localPath, {
        destination,
        metadata: { cacheControl: 'public, max-age=31536000' },
      });

      const uploadedFile = bucket.file(destination);
      await uploadedFile.makePublic();

      const imageUrl = `https://storage.googleapis.com/${bucket.name}/${destination}`;
      await doc.ref.update({ imageUrl });

      console.log(`OK        "${file}" -> "${product.name}"`);
      updated++;
    } catch (err) {
      console.error(`FAILED    "${file}": ${err.message}`);
      notMatched++;
    }
  }

  console.log(`\nDone. Updated ${updated}, not matched/failed ${notMatched}.`);
}

run().catch((err) => {
  console.error('Failed:', err);
  process.exit(1);
});