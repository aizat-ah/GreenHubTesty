// lib/dev/demo_data_seeder.dart
//
// TEMPORARY DEV TOOL — not part of the real app. Generates 20-30 fake
// orders spread across the last 14 days, deliberately engineered so each
// product shows a different demand trend (rising / falling / stable /
// new demand) once you run the prediction algorithm on them.
//
// HOW TO USE:
//   1. Drop this file into lib/dev/.
//   2. Temporarily add a button somewhere reachable (e.g. admin dashboard
//      AppBar) that calls `DemoDataSeeder().seedDemandDemoData(context)`.
//      A minimal example is at the bottom of this file's comments.
//   3. Run it ONCE while logged in (any role works, since order `create`
//      just requires isLoggedIn() per your rules).
//   4. Delete this file + the temporary button afterwards — this is not
//      something that should ship in your final submission.
//
// It reads your REAL products from Firestore (whatever you already have
// — Tomato, Bayam, etc.) so it works regardless of your exact catalog.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      final productsSnap = await _db.collection('products').get();
      if (productsSnap.docs.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No products found — add some products first.')),
        );
        return;
      }

      final products = productsSnap.docs
          .map((d) => (
                id: d.id,
                name: d.data()['name'] as String? ?? 'Unknown',
                unit: d.data()['unit'] as String? ?? 'kg',
                price: (d.data()['price'] as num?)?.toDouble() ?? 5.0,
              ))
          .toList();

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
          batch.set(docRef, _buildOrderMap(product, qty, date));
          orderCount++;
        }

        // This week's orders (0-6 days ago)
        for (var j = 0; j < pattern.thisWeekOrders; j++) {
          final qty = _randomInRange(pattern.thisWeekQtyRange);
          final date = _randomDateDaysAgo(0, 6);
          final docRef = _db.collection('orders').doc();
          batch.set(docRef, _buildOrderMap(product, qty, date));
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

  /// OPTIONAL, separate from `seedDemandDemoData()`. The crop suggestion
  /// engine's "🔥 Hot demand" badge requires ≥25 orders in the current
  /// window AND ≥25% growth vs the previous window (see `_demandLevel()`
  /// in crop_suggestion_service.dart). That volume is unrealistic to hit
  /// incidentally with a normal ~26-order seed spread across 6 products,
  /// so this writes ~26 EXTRA orders concentrated on a single "hero" crop
  /// (0 orders last week, 26 orders this week — trend is automatically
  /// 100% when the previous window is zero) purely so you can see that
  /// badge state in your demo/screenshots.
  ///
  /// Run this AFTER `seedDemandDemoData()`, not instead of it — you want
  /// the realistic mixed data too, this just tops up one crop.
  Future<void> seedHotDemandHero(BuildContext context, {String? productName}) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final productsSnap = await _db.collection('products').get();
      if (productsSnap.docs.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No products found — add some products first.')),
        );
        return;
      }

      final products = productsSnap.docs
          .map((d) => (
                id: d.id,
                name: d.data()['name'] as String? ?? 'Unknown',
                unit: d.data()['unit'] as String? ?? 'kg',
                price: (d.data()['price'] as num?)?.toDouble() ?? 5.0,
              ))
          .toList();

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
        batch.set(docRef, _buildOrderMap(hero, 1, date));
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

  Map<String, dynamic> _buildOrderMap(
    ({String id, String name, String unit, double price}) product,
    int qty,
    DateTime date,
  ) {
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
      'note': '[SEEDED DEMO DATA]',
      'createdAt': Timestamp.fromDate(date),
      'paymentMethod': 'cashOnDelivery',
      'isPaid': true,
    };
  }

  /// Deletes every order this seeder created (identified by the
  /// `[SEEDED DEMO DATA]` marker in the `note` field). Run this before
  /// your final submission/demo so examiners don't see fake orders in
  /// your live database. Safe to run multiple times — does nothing once
  /// there's nothing left to delete.
  Future<void> deleteSeededDemoData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final snap = await _db
          .collection('orders')
          .where('note', isEqualTo: '[SEEDED DEMO DATA]')
          .get();

      if (snap.docs.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No seeded demo orders found.')),
        );
        return;
      }

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      messenger.showSnackBar(
        SnackBar(content: Text('Deleted ${snap.docs.length} seeded demo orders.')),
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

// ─── Example temporary trigger buttons (paste into admin_dashboard.dart's
// AppBar actions, then delete once you're done seeding) ────────────────
//
// IconButton(
//   icon: const Icon(Icons.cloud_upload_outlined),
//   tooltip: 'Seed demo data (DEV ONLY)',
//   onPressed: () => DemoDataSeeder().seedDemandDemoData(context),
// ),
// IconButton(
//   icon: const Icon(Icons.local_fire_department_outlined),
//   tooltip: 'Seed hot-demand hero crop (DEV ONLY)',
//   onPressed: () => DemoDataSeeder().seedHotDemandHero(context),
//   // Or target a specific crop:
//   // onPressed: () => DemoDataSeeder().seedHotDemandHero(context, productName: 'Tomato'),
// ),