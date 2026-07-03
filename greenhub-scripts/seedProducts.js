/**
 * GreenHub Product Seeder
 * ------------------------
 * Populates the Firestore `products` collection with demo data across
 * all 8 GreenHub categories: Leafy Greens, Root Vegetables, Gourds &
 * Squash, Beans & Pods, Herbs & Spices, Fruits & Tomatoes, Mushrooms, Others.
 *
 * SETUP:
 * 1. npm install firebase-admin
 * 2. Get a service account key:
 *    Firebase Console > Project Settings > Service Accounts > Generate new private key
 * 3. Save the downloaded file as `serviceAccountKey.json` next to this script.
 *    (Do NOT commit this file to git — add it to .gitignore.)
 * 4. Run: node seedProducts.js
 *
 * FIELD MODES:
 * - "Full"    -> productId, name, category, price, stockQty, supplierId,
 *                description, imageUrl, createdAt
 * - "Minimal" -> productId, name, category, price, stockQty, supplierId
 *                (only the fields required by the SDS Product schema)
 * Within each category, products alternate Full / Minimal (~50/50 split).
 *
 * SAFE TO RE-RUN: product IDs are deterministic (PRD-2001, PRD-2002, ...),
 * so re-running this script overwrites the same demo docs instead of
 * duplicating them.
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

// ---------------------------------------------------------------------------
// Config — tweak these to match your actual data
// ---------------------------------------------------------------------------

// Replace with real supplier userIds from your `users` collection if you
// want products linked to actual demo suppliers.
const DEMO_SUPPLIER_IDS = ['SUP-1001', 'SUP-1002', 'SUP-1003', 'SUP-1004', 'SUP-1005'];

const PLACEHOLDER_IMAGE = (name) =>
  `https://via.placeholder.com/400x300.png?text=${encodeURIComponent(name)}`;

// ---------------------------------------------------------------------------
// Catalogue — category -> realistic Sabah/Malaysia produce names
// ---------------------------------------------------------------------------

const CATALOGUE = {
  'Leafy Greens': [
    'Bayam Hijau', 'Bayam Merah', 'Kangkung', 'Sawi Bunga', 'Sawi Putih',
    'Kailan', 'Bok Choy', 'Cangkuk Manis', 'Pucuk Ubi', 'Pegaga',
    'Sayur Manis', 'Selada Bulat', 'Selada Rapuh', 'Daun Kesum',
    'Kucai', 'Daun Ubi Kayu', 'Kubis Bulat', 'Kubis Bunga',
  ],
  'Root Vegetables': [
    'Ubi Kayu', 'Ubi Keledek Kuning', 'Ubi Keledek Ungu', 'Lobak Merah',
    'Lobak Putih', 'Halia', 'Kunyit Hidup', 'Ubi Kentang', 'Bawang Besar',
    'Bawang Kecil', 'Keladi', 'Ubi Bengkuang', 'Ubi Rimau', 'Halia Bara',
    'Lengkuas', 'Ubi Gajah',
  ],
  'Gourds & Squash': [
    'Labu Manis', 'Labu Air', 'Peria Katak', 'Petola', 'Timun Hijau',
    'Timun Jepun', 'Skuas', 'Melon Ular', 'Labu Madu', 'Peria Belut',
    'Ciku Timun', 'Labu Loya', 'Gourd Susu', 'Timun Cina', 'Labu Parang',
  ],
  'Beans & Pods': [
    'Kacang Panjang', 'Kacang Botol', 'Kacang Buncis', 'Petai',
    'Kacang Parang', 'Kacang Soya Muda', 'Kacang Hijau', 'Kekacang Kuda',
    'Kacang Kelisa', 'Kacang Tanah Basah', 'Kacang Turi', 'Kacang Bendi',
    'Kacang Empat Segi', 'Kacang Merah Basah', 'Kekacang Jepun',
  ],
  'Herbs & Spices': [
    'Serai', 'Daun Pandan', 'Cili Padi', 'Bawang Putih', 'Ketumbar',
    'Daun Bawang', 'Daun Selasih', 'Halia Muda', 'Kunyit Serbuk',
    'Daun Limau Purut', 'Daun Kunyit', 'Lada Hitam', 'Buah Pelaga',
    'Bunga Kantan', 'Daun Kesum Herba', 'Cili Merah',
  ],
  'Fruits & Tomatoes': [
    'Tomato Bulat', 'Tomato Cheri', 'Terung Ungu', 'Terung Hijau',
    'Betik Muda', 'Betik Masak', 'Nanas Sarawak', 'Pisang Berangan',
    'Pisang Emas', 'Rambutan', 'Durian Musang King', 'Tembikai Merah',
    'Tembikai Kuning', 'Limau Nipis', 'Limau Kasturi', 'Belimbing',
  ],
  'Mushrooms': [
    'Cendawan Tiram Kelabu', 'Cendawan Tiram Putih', 'Cendawan Kancing',
    'Cendawan Enoki', 'Cendawan Shiitake', 'Cendawan Merang', 'Cendawan Susu',
    'Cendawan Ling Zhi', 'Cendawan Abalone', 'Cendawan Bulu Singa',
    'Cendawan Kuku Rusa', 'Cendawan Beech Coklat', 'Cendawan Portobello',
    'Cendawan King Oyster', 'Cendawan Chanterelle Tempatan',
  ],
  'Others': [
    'Brokoli', 'Bunga Kobis Ungu', 'Jagung Manis', 'Kelapa Muda',
    'Bunga Telang', 'Daun Kelor', 'Kompos Organik Premium',
    'Baja Tanaman Organik', 'Benih Sayur Campuran', 'Pasu Tanaman Tanah Liat',
    'Span Pertumbuhan Hidroponik', 'Larutan Nutrien Hidroponik',
    'Span Semaian', 'Pek Sayur Salad Campuran', 'Taugeh',
    'Microgreens Campuran',
  ],
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function randomPrice(min, max) {
  return Math.round((Math.random() * (max - min) + min) * 100) / 100;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// ---------------------------------------------------------------------------
// Build product documents
// ---------------------------------------------------------------------------

function buildProducts() {
  const products = [];
  let counter = 1;

  for (const [category, names] of Object.entries(CATALOGUE)) {
    names.forEach((name, i) => {
      const productId = `PRD-${2000 + counter}`;
      counter++;

      const isFull = i % 2 === 0; // alternate full / minimal within each category

      const base = {
        productId,
        name,
        category,
        price: randomPrice(1.5, 25),
        stockQty: randomInt(5, 100),
        supplierId: pick(DEMO_SUPPLIER_IDS),
      };

      if (isFull) {
        products.push({
          ...base,
          description: `Fresh ${name} sourced from local Sabah farms.`,
          imageUrl: PLACEHOLDER_IMAGE(name),
          createdAt: FieldValue.serverTimestamp(),
        });
      } else {
        products.push(base); // minimal: only schema-required fields
      }
    });
  }

  return products;
}

// ---------------------------------------------------------------------------
// Seed Firestore
// ---------------------------------------------------------------------------

async function seed() {
  const products = buildProducts();
  console.log(`Preparing to seed ${products.length} products across ${Object.keys(CATALOGUE).length} categories...`);

  const batchSize = 400; // Firestore batch write limit is 500
  for (let i = 0; i < products.length; i += batchSize) {
    const batch = db.batch();
    const chunk = products.slice(i, i + batchSize);

    chunk.forEach((product) => {
      const ref = db.collection('products').doc(product.productId);
      batch.set(ref, product);
    });

    await batch.commit();
    console.log(`Committed batch ${Math.floor(i / batchSize) + 1} (${chunk.length} products)`);
  }

  console.log(`Done. Seeded ${products.length} products.`);
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});