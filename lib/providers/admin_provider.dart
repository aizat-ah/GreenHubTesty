import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import '../models/order_model.dart';
import '../services/admin_service.dart';

final adminUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.getUsersStream();
});

final adminOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.getOrdersStream();
});

// Derived Providers for Dashboard Stats
final adminTotalUsersProvider = Provider.autoDispose<int>((ref) {
  final users = ref.watch(adminUsersProvider).value ?? [];
  return users.length;
});

final adminTotalBuyersProvider = Provider.autoDispose<int>((ref) {
  final users = ref.watch(adminUsersProvider).value ?? [];
  return users.where((u) => u.isBuyer).length;
});

final adminTotalSuppliersProvider = Provider.autoDispose<int>((ref) {
  final users = ref.watch(adminUsersProvider).value ?? [];
  return users.where((u) => u.isSupplier).length;
});

final adminTotalRevenueProvider = Provider.autoDispose<double>((ref) {
  final orders = ref.watch(adminOrdersProvider).value ?? [];
  return orders
      .where((o) => o.status == OrderStatus.completed)
      .fold(0.0, (sum, o) => sum + o.totalPrice);
});

final adminPendingOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(adminOrdersProvider).value ?? [];
  return orders.where((o) => o.status == OrderStatus.pending).length;
});

final adminConfirmedOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(adminOrdersProvider).value ?? [];
  return orders.where((o) => o.status == OrderStatus.confirmed).length;
});

final adminCompletedOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(adminOrdersProvider).value ?? [];
  return orders.where((o) => o.status == OrderStatus.completed).length;
});

final adminCancelledOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(adminOrdersProvider).value ?? [];
  return orders.where((o) => o.status == OrderStatus.cancelled).length;
});
