/**
 * GreenHub Product Image Attacher (v2)
 * --------------------------------------
 * Goes through every product in Firestore and attaches a real photo.
 *
 * IMPROVEMENTS OVER v1:
 * - Name matching is case-insensitive/trimmed (avoids silent skips from
 *   casing differences between this map and Firestore).
 * - Tries Wikipedia's article thumbnail FIRST (more reliable for common,
 *   single-concept foods like "Potato", "Garlic", "Okra"), then falls back
 *   to Commons image search if no Wikipedia page/thumbnail exists.
 * - Each product can have multiple candidate search terms; tries each in
 *   order until one returns a real photo.
 * - SMART-SKIP: if a product already has a real (non-placeholder) image,
 *   it's left alone. Set FORCE_REFRESH = true below to redo everything.
 *
 * RUN:
 *   node addProductImages.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// Set to true to re-fetch images even for products that already have one
const FORCE_REFRESH = false;

// ---------------------------------------------------------------------------
// Malay product name (lowercase) -> ordered list of English search candidates
// ---------------------------------------------------------------------------

const QUERY_MAP = {
  // Leafy Greens
  'bayam hijau': ['Green amaranth', 'Spinach'],
  'bayam merah': ['Red amaranth', 'Red spinach'],
  'kangkung': ['Water spinach', 'Kangkong'],
  'sawi bunga': ['Choy sum', 'Flowering mustard greens'],
  'sawi putih': ['Napa cabbage', 'Chinese cabbage'],
  'kailan': ['Chinese kale', 'Gai lan'],
  'bok choy': ['Bok choy', 'Pak choi'],
  'cangkuk manis': ['Sauropus androgynus', 'Katuk'],
  'pucuk ubi': ['Cassava leaves'],
  'pegaga': ['Centella asiatica', 'Pennywort'],
  'sayur manis': ['Katuk', 'Sweet leaf'],
  'selada bulat': ['Iceberg lettuce'],
  'selada rapuh': ['Romaine lettuce'],
  'daun kesum': ['Vietnamese coriander'],
  'kucai': ['Garlic chives', 'Chinese chives'],
  'daun ubi kayu': ['Cassava leaves'],
  'kubis bulat': ['Cabbage'],
  'kubis bunga': ['Cauliflower'],

  // Root Vegetables
  'ubi kayu': ['Cassava', 'Tapioca root'],
  'ubi keledek kuning': ['Sweet potato'],
  'ubi keledek ungu': ['Purple sweet potato'],
  'lobak merah': ['Carrot'],
  'lobak putih': ['Daikon', 'White radish'],
  'halia': ['Ginger'],
  'kunyit hidup': ['Turmeric root', 'Fresh turmeric'],
  'ubi kentang': ['Potato'],
  'bawang besar': ['Yellow onion', 'Brown onion'],
  'bawang kecil': ['Shallot'],
  'bawang merah': ['Shallot', 'Red onion'],
  'keladi': ['Taro root', 'Taro'],
  'ubi bengkuang': ['Jicama'],
  'ubi rimau': ['Yam'],
  'halia bara': ['Ginger'],
  'lengkuas': ['Galangal'],
  'ubi gajah': ['Elephant foot yam'],

  // Gourds & Squash
  'labu manis': ['Pumpkin'],
  'labu air': ['Calabash', 'Bottle gourd'],
  'peria katak': ['Bitter melon', 'Bitter gourd'],
  'petola': ['Ridge gourd', 'Luffa'],
  'timun hijau': ['Cucumber'],
  'timun jepun': ['Japanese cucumber'],
  'skuas': ['Chayote', 'Squash'],
  'melon ular': ['Armenian cucumber', 'Snake melon'],
  'labu madu': ['Butternut squash'],
  'peria belut': ['Bitter melon'],
  'ciku timun': ['Cucumber'],
  'labu loya': ['Winter melon'],
  'gourd susu': ['Bottle gourd', 'Opo squash'],
  'timun cina': ['Chinese cucumber'],
  'labu parang': ['Pumpkin'],

  // Beans & Pods
  'kacang panjang': ['Yardlong bean', 'Long beans'],
  'kacang botol': ['Winged bean'],
  'kacang buncis': ['Green bean', 'French beans'],
  'petai': ['Parkia speciosa', 'Stink bean'],
  'kacang parang': ['Sword bean'],
  'kacang soya muda': ['Edamame'],
  'kacang hijau': ['Mung bean'],
  'kekacang kuda': ['Fava bean'],
  'kacang kelisa': ['Lentil'],
  'kacang tanah basah': ['Peanut'],
  'kacang turi': ['Sesbania grandiflora'],
  'kacang bendi': ['Okra'],
  'bendi': ['Okra'],
  'kacang empat segi': ['Winged bean'],
  'kacang merah basah': ['Kidney bean'],
  'kekacang jepun': ['Edamame'],

  // Herbs & Spices
  'serai': ['Lemongrass'],
  'daun pandan': ['Pandanus amaryllifolius', 'Pandan leaf'],
  'cili padi': ['Bird\'s eye chili', 'Thai chili pepper'],
  'bawang putih': ['Garlic'],
  'ketumbar': ['Coriander', 'Cilantro'],
  'daun bawang': ['Scallion', 'Spring onion'],
  'daun selasih': ['Thai basil'],
  'halia muda': ['Ginger'],
  'kunyit serbuk': ['Turmeric powder', 'Turmeric'],
  'daun limau purut': ['Kaffir lime', 'Makrut lime'],
  'daun kunyit': ['Turmeric leaf', 'Turmeric plant'],
  'lada hitam': ['Black pepper'],
  'buah pelaga': ['Cardamom'],
  'bunga kantan': ['Etlingera elatior', 'Torch ginger'],
  'daun kesum herba': ['Vietnamese coriander'],
  'cili merah': ['Chili pepper', 'Red chili'],

  // Fruits & Tomatoes
  'tomato bulat': ['Tomato'],
  'tomato cheri': ['Cherry tomato'],
  'terung ungu': ['Eggplant', 'Aubergine'],
  'terung hijau': ['Eggplant'],
  'betik muda': ['Green papaya'],
  'betik masak': ['Papaya'],
  'nanas sarawak': ['Pineapple'],
  'pisang berangan': ['Banana'],
  'pisang emas': ['Lady finger banana', 'Banana'],
  'rambutan': ['Rambutan'],
  'durian musang king': ['Durian'],
  'tembikai merah': ['Watermelon'],
  'tembikai kuning': ['Yellow watermelon', 'Watermelon'],
  'limau nipis': ['Key lime', 'Lime'],
  'limau kasturi': ['Calamansi'],
  'belimbing': ['Carambola', 'Starfruit'],

  // Mushrooms
  'cendawan tiram kelabu': ['Oyster mushroom'],
  'cendawan tiram putih': ['Oyster mushroom'],
  'cendawan kancing': ['Button mushroom', 'Agaricus bisporus'],
  'cendawan enoki': ['Enoki'],
  'cendawan shiitake': ['Shiitake'],
  'cendawan merang': ['Volvariella volvacea', 'Straw mushroom'],
  'cendawan susu': ['Lactarius', 'Mushroom'],
  'cendawan ling zhi': ['Ganoderma lucidum', 'Reishi mushroom'],
  'cendawan abalone': ['Abalone mushroom', 'Oyster mushroom'],
  'cendawan bulu singa': ['Lion\'s mane mushroom'],
  'cendawan kuku rusa': ['Mushroom'],
  'cendawan beech coklat': ['Beech mushroom'],
  'cendawan portobello': ['Portobello mushroom'],
  'cendawan king oyster': ['King oyster mushroom'],
  'cendawan chanterelle tempatan': ['Chanterelle'],

  // Others
  'brokoli': ['Broccoli'],
  'bunga kobis ungu': ['Purple cauliflower', 'Cauliflower'],
  'jagung manis': ['Sweet corn'],
  'kelapa muda': ['Coconut'],
  'bunga telang': ['Clitoria ternatea', 'Butterfly pea'],
  'daun kelor': ['Moringa oleifera', 'Moringa'],
  'kompos organik premium': ['Compost'],
  'baja tanaman organik': ['Fertilizer'],
  'benih sayur campuran': ['Vegetable seeds'],
  'pasu tanaman tanah liat': ['Flowerpot', 'Clay pot'],
  'span pertumbuhan hidroponik': ['Hydroponics'],
  'larutan nutrien hidroponik': ['Hydroponics'],
  'span semaian': ['Seedling'],
  'pek sayur salad campuran': ['Salad'],
  'taugeh': ['Bean sprout'],
  'microgreens campuran': ['Microgreen'],
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function normalizeKey(name) {
  return name.trim().toLowerCase().replace(/\s+/g, ' ');
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function upsizeThumbnail(url, width) {
  return url.replace(/\/(\d+)px-/, `/${width}px-`);
}

function isPlaceholder(url) {
  return !url || url.includes('via.placeholder.com');
}

// Try Wikipedia's article summary API — most reliable for common single foods
async function fetchWikipediaThumbnail(title) {
  try {
    const url = `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(
      title.replace(/ /g, '_')
    )}`;
    const res = await fetch(url, {
      headers: { 'User-Agent': 'GreenHubFYP-ImageFetcher/1.0 (UTM student project)' },
    });
    if (!res.ok) return null;
    const data = await res.json();
    if (data?.thumbnail?.source) {
      return upsizeThumbnail(data.thumbnail.source, 500);
    }
    return null;
  } catch {
    return null;
  }
}

// Fallback: Wikimedia Commons image search
async function fetchCommonsImage(query) {
  try {
    const searchUrl =
      'https://commons.wikimedia.org/w/api.php' +
      '?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=5' +
      `&gsrsearch=${encodeURIComponent('filetype:bitmap ' + query)}` +
      '&prop=imageinfo&iiprop=url&iiurlwidth=500';

    const res = await fetch(searchUrl, {
      headers: { 'User-Agent': 'GreenHubFYP-ImageFetcher/1.0 (UTM student project)' },
    });
    const data = await res.json();
    const pages = data?.query?.pages;
    if (!pages) return null;

    for (const page of Object.values(pages)) {
      const info = page.imageinfo?.[0];
      const link = info?.thumburl || info?.url;
      if (link && /\.(jpg|jpeg|png)$/i.test(link)) {
        return link;
      }
    }
    return null;
  } catch {
    return null;
  }
}

// Try every candidate term, Wikipedia first, then Commons as fallback
async function fetchImageForCandidates(candidates) {
  for (const term of candidates) {
    const wiki = await fetchWikipediaThumbnail(term);
    if (wiki) return wiki;
  }
  for (const term of candidates) {
    const commons = await fetchCommonsImage(term);
    if (commons) return commons;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function run() {
  const snapshot = await db.collection('products').get();
  console.log(`Found ${snapshot.size} products in Firestore.\n`);

  let updated = 0;
  let skippedHasImage = 0;
  let skippedNoMapping = 0;
  let stillMissing = 0;

  for (const doc of snapshot.docs) {
    const product = doc.data();

    if (!FORCE_REFRESH && !isPlaceholder(product.imageUrl)) {
      skippedHasImage++;
      continue;
    }

    const key = normalizeKey(product.name || '');
    const candidates = QUERY_MAP[key];

    if (!candidates) {
      console.log(`NO MAPPING  "${product.name}" — add it to QUERY_MAP`);
      skippedNoMapping++;
      continue;
    }

    const imageUrl = await fetchImageForCandidates(candidates);

    if (imageUrl) {
      await doc.ref.update({ imageUrl });
      console.log(`OK          "${product.name}" -> ${imageUrl}`);
      updated++;
    } else {
      console.log(`STILL MISS  "${product.name}" — tried: ${candidates.join(', ')}`);
      stillMissing++;
    }

    await sleep(300); // be polite to the free APIs
  }

  console.log(
    `\nDone. Updated ${updated}, already had images ${skippedHasImage}, ` +
      `no mapping ${skippedNoMapping}, still missing ${stillMissing}.`
  );
}

run().catch((err) => {
  console.error('Failed:', err);
  process.exit(1);
});