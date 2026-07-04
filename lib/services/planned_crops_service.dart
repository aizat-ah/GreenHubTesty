// lib/services/planned_crops_service.dart
//
// Persists a supplier's planting plan (the set of crop names they've
// added via "Add to planting plan") to Firestore, so it survives app
// restarts and syncs across devices — one document per supplier at
// plannedCrops/{supplierUid}, holding a `crops` string array.

import 'package:cloud_firestore/cloud_firestore.dart';

class PlannedCropsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _plannedCrops => _db.collection('plannedCrops');

  Stream<Set<String>> streamPlannedCrops(String supplierUid) {
    return _plannedCrops.doc(supplierUid).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final crops = data?['crops'] as List<dynamic>? ?? const [];
      return crops.cast<String>().toSet();
    });
  }

  Future<void> toggle(String supplierUid, String cropName) async {
    final ref = _plannedCrops.doc(supplierUid);
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>?;
    final current = (data?['crops'] as List<dynamic>? ?? const [])
        .cast<String>()
        .toSet();

    final isPlanned = current.contains(cropName);
    await ref.set(
      {
        'crops': isPlanned
            ? FieldValue.arrayRemove([cropName])
            : FieldValue.arrayUnion([cropName]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
