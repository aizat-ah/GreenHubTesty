// lib/features/orders/checkout_screen.dart
//
// CHANGES in current file:
//   - Added a "Payment Method" section: Cash on Delivery vs Card (Stripe).
//   - `_placeOrder` now passes the selected PaymentMethod to placeOrder().
//   - Button label reflects the choice ("Place Order" for COD vs
//     "Pay RM x.xx" for card) so it's clear a card charge is about to
//     happen.
//   - Error snackbar now also fires on payment cancellation, which is
//     expected/normal, not a bug — just informational.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _noteController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.whenData((data) => data).value;
    if (user == null) return;

    final order = await ref.read(placeOrderProvider.notifier).placeOrder(
          user: user,
          note: _noteController.text,
          paymentMethod: _paymentMethod,
        );

    if (!mounted) return;

    if (order != null) {
      context.pushReplacement('/order-success', extra: order);
    } else {
      final error = ref.read(placeOrderProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Failed to place order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartItemsProvider);
    final total = ref.watch(cartTotalProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.whenData((data) => data).value;
    final orderState = ref.watch(placeOrderProvider);
    final isLoading = orderState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info
                  _SectionCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Your Details',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Name',
                          value: user?.name ?? '—',
                        ),
                        _divider(),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'WhatsApp',
                          value: user?.phone ?? '—',
                        ),
                        _divider(),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? '—',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order items
                  _SectionCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Order Summary',
                    child: Column(
                      children: [
                        ...cartItems.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Column(
                            children: [
                              if (i > 0) _divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.quantity} × ${item.product.formattedPrice} / ${item.product.unit}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'RM ${item.subtotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'RM ${total.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NEW: Payment method selector
                  _SectionCard(
                    icon: Icons.payment_rounded,
                    title: 'Payment Method',
                    child: Column(
                      children: [
                        _PaymentOptionTile(
                          icon: Icons.money_rounded,
                          label: PaymentMethod.cashOnDelivery.label,
                          selected: _paymentMethod == PaymentMethod.cashOnDelivery,
                          onTap: () => setState(
                              () => _paymentMethod = PaymentMethod.cashOnDelivery),
                        ),
                        const SizedBox(height: 10),
                        _PaymentOptionTile(
                          icon: Icons.credit_card_rounded,
                          label: 'Card (Visa, Mastercard)',
                          selected: _paymentMethod == PaymentMethod.cardStripe,
                          onTap: () => setState(
                              () => _paymentMethod = PaymentMethod.cardStripe),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  _SectionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Order Notes',
                    child: TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'e.g. Please pack separately, deliver after 3pm',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                        counterStyle: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Place order / Pay button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _paymentMethod == PaymentMethod.cardStripe
                                ? 'Pay RM ${total.toStringAsFixed(2)}'
                                : 'Place Order — RM ${total.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: AppTheme.divider.withValues(alpha: 0.6), height: 1),
      );
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textLight),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── NEW: Payment option tile ──────────────────────────────────────────────────

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surfaceDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppTheme.primary : AppTheme.textLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primary : AppTheme.textDark,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppTheme.primary : AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}