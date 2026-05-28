// lib/providers/driver_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../models/order_model.dart';
import '../services/driver_service.dart';

// All drivers
final allDriversProvider = StreamProvider.autoDispose<List<DriverModel>>((ref) {
  return ref.watch(driverServiceProvider).driversStream();
});

// Available drivers only
final availableDriversProvider =
    StreamProvider.autoDispose<List<DriverModel>>((ref) {
  return ref.watch(driverServiceProvider).availableDriversStream();
});

// Confirmed orders waiting for a driver
final confirmedOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  return ref.watch(driverServiceProvider).confirmedOrdersStream();
});

// Driver's own deliveries (for driver dashboard)
final driverOrdersProvider =
    StreamProvider.autoDispose.family<List<OrderModel>, String>(
  (ref, driverId) =>
      ref.watch(driverServiceProvider).driverOrdersStream(driverId),
);

// Total drivers count (for admin stats)
final totalDriversCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(allDriversProvider).value?.length ?? 0;
});

final availableDriversCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(allDriversProvider).value
          ?.where((d) => d.status == DriverStatus.available)
          .length ??
      0;
});

final onDeliveryDriversCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(allDriversProvider).value
          ?.where((d) => d.status == DriverStatus.onDelivery)
          .length ??
      0;
});
