import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

class WhatsAppService {
  // Malaysia example: 60123456789
  static const String _sellerPhone = '60125669042';

  // Build a formatted order message and open WhatsApp
  static Future<bool> sendOrderToSeller(OrderModel order) async {
    final message = _buildOrderMessage(order);
    return _launch(_sellerPhone, message);
  }

  // Customer can also reach seller directly
  static Future<bool> contactSeller({String? message}) async {
    return _launch(
      _sellerPhone,
      message ?? 'Hi, I have a question about my order.',
    );
  }

  static String _buildOrderMessage(OrderModel order) {
    final buffer = StringBuffer();

    buffer.writeln('🥬 *New Order from GreenHub App*');
    buffer.writeln('─────────────────────');
    buffer.writeln('👤 *Customer:* ${order.customerName}');
    buffer.writeln('📱 *Phone:* ${order.customerPhone}');
    buffer.writeln('🔖 *Order ID:* #${order.id.substring(0, 8).toUpperCase()}');
    buffer.writeln('');
    buffer.writeln('🛒 *Items:*');

    for (final item in order.items) {
      buffer.writeln(
        '  • ${item.productName} x${item.quantity} ${item.unit}'
        ' — RM ${item.subtotal.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('💰 *Total: ${order.formattedTotal}*');
    buffer.writeln('💵 Payment: Cash on Delivery');

    if (order.note.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📝 *Note:* ${order.note}');
    }

    buffer.writeln('');
    buffer.writeln('─────────────────────');
    buffer.writeln('Please confirm this order. Thank you! 🙏');

    return buffer.toString();
  }

  static Future<bool> _launch(String phone, String message) async {
    final encoded = Uri.encodeComponent(message);
    final waUrl = Uri.parse('https://wa.me/$phone?text=$encoded');

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
