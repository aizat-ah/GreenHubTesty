// lib/dev/demo_data_seeder.dart
//
// TEMPORARY DEV TOOL — not part of the real app. Generates fake orders
// spread across recent days, engineered so products show different
// demand trends (rising / falling / stable / new demand) once you run
// the prediction algorithm on them.
//
// HOW TO USE:
//   1. Drop this file into lib/dev/.
//   2. Temporarily add a button somewhere reachable (e.g. supplier
//      dashboard AppBar) that calls the seed functions below.
//   3. Run it while logged in (any role works, since order `create`
//      just requires isLoggedIn() per your rules).
//   4. Delete this file + the temporary button afterwards — this is not
//      something that should ship in your final submission.
//
// It reads your REAL products from Firestore (whatever you already have
// — Tomato, Bayam, etc.) so it works regardless of your exact catalog.
//
// METHODS:
//   seedDemandDemoData()   — the original ~20-30 order baseline batch,
//                            spread across 4 demand patterns.
//   seedFreshSalesBatch()  — NEW: tops up with an EXTRA randomized batch
//                            of orders (wider date range, more variety
//                            per product), for when you need more volume
//                            of "sold recently" data without re-running
//                            the exact same fixed pattern. Safe to call
//                            multiple times — each call is a distinct,
//                            independently-tagged batch.
//   seedHotDemandHero()    — tops up ONE crop with ~26 orders this week
//                            so it crosses the "🔥 Hot demand" threshold.
//   deleteSeededDemoData() — deletes every order created by ANY of the
//                            above (matches on the note prefix), so run
//                            this before your final submission/demo.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Prefix used to tag every order this tool creates, so cleanup can find
/// them regardless of which method or batch created them.
const _seedNotePrefix = '[SEEDED DEMO DATA';

class DemoDataSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _random = Random();

  /// The 4 demand patterns we cycle through across your product list.
  /// Each defines how many orders to create in each time bucket, and the
  /// quantity range per order — tuned to clearly cross the ±20% threshold.
  static const _patterns = [
    _Pattern(name: 'rising', lastWeekOrders: 2, lastWeekQtyRange: (1, 1), thisWeekOrders: 3, thisWeekQtyRange: (2, 3)),
    _Pattern(name: 'falling', lastWeekOrders: 3, lastWeekQtyRange: (2, 3), thisWeekOrders: 2, thisWeekQtyRange: (1, 1)),
    _Pattern(name: 'stable', lastWeekOrders: 2, lastWeekQtyRange: (2, 2), thisWeekOrders: 2, thisWeekQtyRange: (2, 2)),
    _Pattern(name: 'newDemand', lastWeekOrders: 0, lastWeekQtyRange: (0, 0), thisWeekOrders: 2, thisWeekQtyRange: (2, 3)),
  ];

  Future<void> seedDemandDemoData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final products = await _loadProducts();
      if (products.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No products found — add some products first.')),
        );
        return;
      }

      final batch = _db.batch();
      int orderCount = 0;

      for (var i = 0; i < products.length; i++) {
        final product = products[i];
        final pattern = _patterns[i % _patterns.length];

        // Last week's orders (7-13 days ago)
        for (var j = 0; j < pattern.lastWeekOrders; j++) {
          final qty = _randomInRange(pattern.lastWeekQtyRange);
          final date = _randomDateDaysAgo(7, 13);
          final docRef = _db.collection('orders').doc();
          batch.set(docRef, _buildOrderMap(product, qty, date, batchTag: 'baseline'));
          orderCount++;
        }

        // This week's orders (0-6 days ago)
        for (var j = 0; j < pattern.thisWeekOrders; j++) {
          final qty = _randomInRange(pattern.thisWeekQtyRange);
          final date = _randomDateDaysAgo(0, 6);
          final docRef = _db.collection('orders').doc();
          batch.set(docRef, _buildOrderMap(product, qty, date, batchTag: 'baseline'));
          orderCount++;
        }
      }

      await batch.commit();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Seeded $orderCount demo orders across ${products.length} products. '
            'Refresh the demand prediction screen to see trends.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Seeding failed: $e')));
    }
  }

  /// NEW: Adds an EXTRA, independently-randomized batch of orders on top
  /// of whatever already exists. Unlike `seedDemandDemoData()` (which
  /// always writes the same fixed pattern), this generates a fresh,
  /// varied spread every time it's called — wider date range (up to 30
  /// days back), random order counts per product (3-8), random
  /// quantities (1-4) — so repeated calls keep building up realistic
  /// volume instead of duplicating an identical shape.
  ///
  /// Each call is tagged with its own timestamp so you can tell batches
  /// apart in Firestore if you ever need to (note field), though
  /// `deleteSeededDemoData()` clears all of them regardless of batch.
  Future<void> seedFreshSalesBatch(
    BuildContext context, {
    int minOrdersPerProduct = 3,
    int maxOrdersPerProduct = 8,
    int maxDaysBack = 30,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final products = await _loadProducts();
      if (products.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No products found — add some products first.')),
        );
        return;
      }

      final batchTag = 'batch-${DateTime.now().millisecondsSinceEpoch}';
      final batch = _db.batch();
      int orderCount = 0;

      for (final product in products) {
        final ordersForThisProduct = minOrdersPerProduct +
            _random.nextInt(maxOrdersPerProduct - minOrdersPerProduct + 1);

        for (var j = 0; j < ordersForThisProduct; j++) {
          final qty = 1 + _random.nextInt(4); // 1-4
          final date = _randomDateDaysAgo(0, maxDaysBack);
          final docRef = _db.collection('orders').doc();
          batch.set(docRef, _buildOrderMap(product, qty, date, batchTag: batchTag));
          orderCount++;
        }
      }

      await batch.commit();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added a fresh batch: $orderCount new orders across ${products.length} products.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Batch seeding failed: $e')));
    }
  }

  /// OPTIONAL, separate from the other two. The crop suggestion engine's
  /// "🔥 Hot demand" badge requires ≥25 orders in the current window AND
  /// ≥25% growth vs the previous window (see `_demandLevel()` in
  /// crop_suggestion_service.dart). This tops up one "hero" crop with
  /// ~26 orders this week (0 last week, so trend is automatically 100%)
  /// purely so you can see that badge state in your demo/screenshots.
  Future<void> seedHotDemandHero(BuildContext context, {String? productName}) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final products = await _loadProducts();
      if (products.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No products found — add some products first.')),
        );
        return;
      }

      final hero = productName == null
          ? products.first
          : products.firstWhere(
              (p) => p.name.toLowerCase() == productName.toLowerCase(),
              orElse: () => products.first,
            );

      const heroOrderCount = 26; // clears the ≥25 orders threshold

      final batch = _db.batch();
      for (var i = 0; i < heroOrderCount; i++) {
        final date = _randomDateDaysAgo(0, 6); // all within current window
        final docRef = _db.collection('orders').doc();
        batch.set(docRef, _buildOrderMap(hero, 1, date, batchTag: 'hero'));
      }
      await batch.commit();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Seeded $heroOrderCount extra orders for "${hero.name}" — '
            'it should now show as 🔥 Hot demand.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Hero seeding failed: $e')));
    }
  }

  Future<List<({String id, String name, String unit, double price})>> _loadProducts() async {
    final productsSnap = await _db.collection('products').get();
    return productsSnap.docs
        .map((d) => (
              id: d.id,
              name: d.data()['name'] as String? ?? 'Unknown',
              unit: d.data()['unit'] as String? ?? 'kg',
              price: (d.data()['price'] as num?)?.toDouble() ?? 5.0,
            ))
        .toList();
  }

  Map<String, dynamic> _buildOrderMap(
    ({String id, String name, String unit, double price}) product,
    int qty,
    DateTime date, {
    required String batchTag,
  }) {
    return {
      'customerId': 'demo-buyer',
      'customerName': 'Demo Buyer',
      'customerPhone': '60100000000',
      'items': [
        {
          'productId': product.id,
          'productName': product.name,
          'unit': product.unit,
          'quantity': qty,
          'price': product.price,
        }
      ],
      'totalPrice': product.price * qty,
      'status': 'completed',
      'note': '$_seedNotePrefix:$batchTag]',
      'createdAt': Timestamp.fromDate(date),
      'paymentMethod': 'cashOnDelivery',
      'isPaid': true,
    };
  }

  /// Deletes every order any of the seed methods created (matches the
  /// `[SEEDED DEMO DATA...` note prefix, so it catches baseline, fresh
  /// batches, and hero data in one go). Run this before your final
  /// submission/demo so examiners don't see fake orders in your live
  /// database. Safe to run multiple times.
  Future<void> deleteSeededDemoData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Firestore can't do a "starts with" query directly on arbitrary
      // strings well, so we range-query the note field using the prefix
      // trick: [prefix, prefix + \uf8ff) covers all strings starting
      // with prefix.
      final snap = await _db
          .collection('orders')
          .where('note', isGreaterThanOrEqualTo: _seedNotePrefix)
          .where('note', isLessThan: '$_seedNotePrefix\uf8ff')
          .get();

      if (snap.docs.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No seeded demo orders found.')),
        );
        return;
      }

      // Firestore batches cap at 500 writes — chunk just in case.
      final docs = snap.docs;
      for (var i = 0; i < docs.length; i += 500) {
        final chunk = docs.skip(i).take(500);
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Deleted ${docs.length} seeded demo orders.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Cleanup failed: $e')));
    }
  }

  int _randomInRange((int, int) range) {
    final (min, max) = range;
    if (min == max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  DateTime _randomDateDaysAgo(int minDays, int maxDays) {
    final daysAgo = minDays + _random.nextInt(maxDays - minDays + 1);
    final hoursOffset = _random.nextInt(24);
    return DateTime.now()
        .subtract(Duration(days: daysAgo, hours: hoursOffset));
  }
}

class _Pattern {
  final String name;
  final int lastWeekOrders;
  final (int, int) lastWeekQtyRange;
  final int thisWeekOrders;
  final (int, int) thisWeekQtyRange;

  const _Pattern({
    required this.name,
    required this.lastWeekOrders,
    required this.lastWeekQtyRange,
    required this.thisWeekOrders,
    required this.thisWeekQtyRange,
  });
}

// ─── Example temporary trigger buttons (paste into your supplier page's
// AppBar actions, then delete once you're done seeding) ────────────────
//
// IconButton(
//   icon: const Icon(Icons.cloud_upload_outlined),
//   tooltip: 'Seed baseline demo data (DEV ONLY)',
//   onPressed: () => DemoDataSeeder().seedDemandDemoData(context),
// ),
// IconButton(
//   icon: const Icon(Icons.add_chart_outlined),
//   tooltip: 'Add fresh sales batch (DEV ONLY)',
//   onPressed: () => DemoDataSeeder().seedFreshSalesBatch(context),
// ),
// IconButton(
//   icon: const Icon(Icons.local_fire_department_outlined),
//   tooltip: 'Seed hot-demand hero crop (DEV ONLY)',
//   onPressed: () => DemoDataSeeder().seedHotDemandHero(context),
// ),
// IconButton(
//   icon: const Icon(Icons.delete_sweep_outlined),
//   tooltip: 'Delete all seeded demo data (DEV ONLY)',
//   onPressed: () => DemoDataSeeder().deleteSeededDemoData(context),
// ),