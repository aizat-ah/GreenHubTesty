// lib/services/payment_service.dart
//
// NEW FILE. Wraps the two-step Stripe flow:
//   1. Call the `createPaymentIntent` Cloud Function (asia-southeast1) to
//      get a client secret.
//   2. Initialize + present Stripe's built-in Payment Sheet using it.
//
// Throws a `PaymentFailure` (with a human-readable message) on any error
// or if the buyer cancels — the caller (order_provider) decides what to
// do with that (e.g. delete the pending order, show the message).

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());

class PaymentService {
  // Must match the region your Cloud Function was deployed to.
  static const _region = 'us-central1';

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: _region);

  /// Runs the full Stripe payment flow for [orderId] / [amountInRM].
  Future<void> payWithStripe({
    required String orderId,
    required double amountInRM,
  }) async {
    // Stripe expects the smallest currency unit — for MYR that's sen.
    final amountInSen = (amountInRM * 100).round();

    final HttpsCallableResult result;
    try {
      result = await _functions.httpsCallable('createPaymentIntent').call({
        'amount': amountInSen,
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (e) {
      print('[Stripe] FirebaseFunctionsException code=${e.code} '
          'message=${e.message} details=${e.details}');
      throw PaymentFailure(
        e.message ?? 'Could not start payment. Please try again.',
      );
    } catch (e) {
      print('[Stripe] Unexpected error type: ${e.runtimeType} — $e');
      rethrow;
    }

    final clientSecret = result.data['clientSecret'] as String?;
    if (clientSecret == null) {
      throw PaymentFailure('Could not start payment. Please try again.');
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'GreenHub',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      // Checked as a string rather than a specific enum value, since the
      // exact enum name for "user cancelled" has changed across
      // flutter_stripe versions (Canceled / canceled / userCancelled).
      final codeStr = e.error.code.toString().toLowerCase();
      final isCancelled = codeStr.contains('cancel');

      throw PaymentFailure(
        isCancelled
            ? 'Payment cancelled.'
            : (e.error.localizedMessage ?? 'Payment failed. Please try again.'),
        cancelled: isCancelled,
      );
    }
  }
}

class PaymentFailure implements Exception {
  final String message;
  final bool cancelled;

  PaymentFailure(this.message, {this.cancelled = false});

  @override
  String toString() => message;
}