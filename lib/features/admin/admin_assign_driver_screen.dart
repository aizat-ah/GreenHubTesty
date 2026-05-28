// lib/features/admin/admin_assign_driver_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/driver_model.dart';
import '../../models/order_model.dart';
import '../../providers/driver_provider.dart';
import '../../services/driver_service.dart';

class AdminAssignDriverScreen extends ConsumerWidget {
  const AdminAssignDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(confirmedOrdersProvider);
    final driversAsync = ref.watch(allDriversProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Assign Drivers',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmpty();
          }
          return driversAsync.when(
            data: (drivers) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (ctx, i) => _OrderAssignCard(
                order: orders[i],
                allDrivers: drivers,
              ),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: AppTheme.success),
          const SizedBox(height: 12),
          Text('All orders assigned!',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMid)),
          const SizedBox(height: 6),
          Text('No confirmed orders awaiting a driver.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}

class _OrderAssignCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final List<DriverModel> allDrivers;

  const _OrderAssignCard(
      {required this.order, required this.allDrivers});

  @override
  ConsumerState<_OrderAssignCard> createState() => _OrderAssignCardState();
}

class _OrderAssignCardState extends ConsumerState<_OrderAssignCard> {
  bool _isLoading = false;

  List<DriverModel> get _availableDrivers =>
      widget.allDrivers.where((d) => d.isAvailable).toList();

  Future<void> _assign(DriverModel driver) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(driverServiceProvider).assignDriverToOrder(
            orderId: widget.order.id,
            driver: driver,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${driver.name} assigned to order #${widget.order.id.substring(0, 6).toUpperCase()}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDriverPicker() {
    if (_availableDrivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available drivers at the moment.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DriverPickerSheet(
        drivers: _availableDrivers,
        onSelect: (d) {
          Navigator.pop(context);
          _assign(d);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
    final hasDriver = order.driverId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${order.id.substring(0, 6).toUpperCase()}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark),
                  ),
                ),
                Text(
                  order.formattedTotal,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: 13, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(order.customerPhone,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textMid)),
                const Spacer(),
                Text(dateStr,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
            const SizedBox(height: 8),
            // Items summary
            Text(
              order.items
                  .map((i) => '${i.quantity}× ${i.productName}')
                  .join(', '),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.textMid),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20, color: AppTheme.divider),
            // Driver assignment row
            if (hasDriver)
              _AssignedDriverRow(order: order)
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showDriverPicker,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.person_add_outlined, size: 18),
                  label: Text(
                    'Assign Driver',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignedDriverRow extends ConsumerStatefulWidget {
  final OrderModel order;
  const _AssignedDriverRow({required this.order});

  @override
  ConsumerState<_AssignedDriverRow> createState() =>
      _AssignedDriverRowState();
}

class _AssignedDriverRowState extends ConsumerState<_AssignedDriverRow> {
  bool _removing = false;

  Future<void> _unassign() async {
    setState(() => _removing = true);
    try {
      await ref.read(driverServiceProvider).unassignDriver(
            orderId: widget.order.id,
            driverId: widget.order.driverId!,
          );
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining,
              size: 20, color: AppTheme.success),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.driverName ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark),
                ),
                Text(
                  '${o.driverPhone ?? ''} · ${o.driverVehiclePlate ?? ''}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textMid),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _removing ? null : _unassign,
            child: Text(
              _removing ? '...' : 'Remove',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Driver Picker Sheet ───────────────────────────────────────────────────────

class _DriverPickerSheet extends StatelessWidget {
  final List<DriverModel> drivers;
  final void Function(DriverModel) onSelect;

  const _DriverPickerSheet(
      {required this.drivers, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Driver',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${drivers.length} available',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          ...drivers.map(
            (d) => ListTile(
              onTap: () => onSelect(d),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  d.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
              title: Text(
                d.name,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${d.vehicleType} · ${d.vehiclePlate} · ${d.phone}',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textMid),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🟢 Available',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
