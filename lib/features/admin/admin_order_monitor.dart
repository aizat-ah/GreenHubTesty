import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';

enum _OrderFilter { all, pending, confirmed, completed, cancelled }

class AdminOrderMonitor extends ConsumerStatefulWidget {
  const AdminOrderMonitor({super.key});

  @override
  ConsumerState<AdminOrderMonitor> createState() => _AdminOrderMonitorState();
}

class _AdminOrderMonitorState extends ConsumerState<AdminOrderMonitor> {
  final TextEditingController _searchController = TextEditingController();
  _OrderFilter _currentFilter = _OrderFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Monitor'),
      ),
      body: Column(
        children: [
          _buildSummaryBar(ref),
          _buildFilters(),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filtered = _filterOrders(orders);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading orders: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(WidgetRef ref) {
    final pending = ref.watch(adminPendingOrdersCountProvider);
    final confirmed = ref.watch(adminConfirmedOrdersCountProvider);
    final completed = ref.watch(adminCompletedOrdersCountProvider);
    final cancelled = ref.watch(adminCancelledOrdersCountProvider);

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryCount(label: 'Pending', count: pending, color: AppTheme.warning),
          _SummaryCount(label: 'Confirmed', count: confirmed, color: AppTheme.info),
          _SummaryCount(label: 'Completed', count: completed, color: AppTheme.success),
          _SummaryCount(label: 'Cancelled', count: cancelled, color: AppTheme.error),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search by Buyer Name or Order ID...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(_OrderFilter.all, 'All'),
                const SizedBox(width: 8),
                _buildFilterChip(_OrderFilter.pending, 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip(_OrderFilter.confirmed, 'Confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip(_OrderFilter.completed, 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip(_OrderFilter.cancelled, 'Cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_OrderFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _currentFilter = filter),
      backgroundColor: AppTheme.surfaceDim,
      selectedColor: AppTheme.primary.withOpacity(0.15),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? AppTheme.primaryDark : AppTheme.textMid,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> allOrders) {
    final query = _searchController.text.toLowerCase();
    return allOrders.where((order) {
      final matchesSearch = order.customerName.toLowerCase().contains(query) ||
          order.id.toLowerCase().contains(query);

      bool matchesRole = true;
      if (_currentFilter == _OrderFilter.pending) matchesRole = order.status == OrderStatus.pending;
      if (_currentFilter == _OrderFilter.confirmed) matchesRole = order.status == OrderStatus.confirmed;
      if (_currentFilter == _OrderFilter.completed) matchesRole = order.status == OrderStatus.completed;
      if (_currentFilter == _OrderFilter.cancelled) matchesRole = order.status == OrderStatus.cancelled;

      return matchesSearch && matchesRole;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No orders found matching filters.',
        style: GoogleFonts.inter(color: AppTheme.textMid, fontSize: 16),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isPending = order.status == OrderStatus.pending;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPending ? AppTheme.warning : AppTheme.divider, width: isPending ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: GoogleFonts.inter(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _updateOrderStatusDialog(order),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.status.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Customer Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse('tel:${order.customerPhone}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Text(
                          order.customerPhone,
                          style: GoogleFonts.inter(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                  tooltip: 'WhatsApp',
                  onPressed: () async {
                    String phone = order.customerPhone.replaceAll(RegExp(r'\D'), '');
                    if (phone.startsWith('0')) {
                      phone = '6$phone'; // assuming Malaysia
                    }
                    final uri = Uri.parse('https://wa.me/$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Order Items',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}${item.unit.isNotEmpty ? ' ${item.unit}' : ''} x ${item.productName}',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
                            ),
                          ),
                          Text(
                            item.formattedSubtotal,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.note,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textDark,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      order.formattedTotal,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.warning;
      case OrderStatus.confirmed:
        return AppTheme.info;
      case OrderStatus.completed:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return AppTheme.error;
    }
  }

  Future<void> _updateOrderStatusDialog(OrderModel order) async {
    final status = await showDialog<OrderStatus>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: OrderStatus.values.map((s) {
              return ListTile(
                leading: Text(s.emoji),
                title: Text(s.label),
                trailing: order.status == s ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () => Navigator.pop(context, s),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (status != null && status != order.status) {
      try {
        await ref.read(adminServiceProvider).updateOrderStatus(order.id, status);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating status: $e')),
          );
        }
      }
    }
  }
}

class _SummaryCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMid,
          ),
        ),
      ],
    );
  }
}
