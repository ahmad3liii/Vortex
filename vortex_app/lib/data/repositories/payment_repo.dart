import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentRepository {
  final ApiService _apiService;

  PaymentRepository(this._apiService);

  Future<List<PaymentModel>> getPaymentHistory({int page = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        return [];
      }

      final response = await _apiService.getMyOrders(userId);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // ✅ الآن تعمل هذه الدالة بشكل صحيح
        return data
            .map(
              (order) =>
                  PaymentModel.fromOrderMap(order as Map<String, dynamic>),
            )
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  Future<PaymentModel> createPaymentIntent({
    required int orderId,
    required double amount,
  }) async {
    try {
      final response = await _apiService.createPaymentIntent(orderId);

      if (response.statusCode == 200) {
        return PaymentModel(
          id: response.data['payment_id'].toString(),
          orderId: orderId.toString(),
          userId: '',
          amount: amount,
          currency: 'usd',
          status: 'pending',
          paymentMethod: 'card',
          stripePaymentIntentId: response.data['client_secret'],
          createdAt: DateTime.now(),
          completedAt: null,
        );
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // أضف هذه الدالة في PaymentRepository class
  Future<Map<String, dynamic>> purchaseProduct({
    required int buyerId,
    required int productId,
    required int quantity,
    String? shippingAddress,
  }) async {
    try {
      // 1. إنشاء طلب جديد
      final orderResponse = await _apiService.createOrder(
        buyer_id: buyerId,
        product_id: productId,
        quantity: quantity,
        shipping_address: shippingAddress,
      );

      if (orderResponse.statusCode != 201) {
        throw Exception('Failed to create order');
      }

      final orderData = orderResponse.data;
      final orderId = orderData['order_id'];

      // 2. إنشاء payment intent
      final paymentResponse = await _apiService.createPaymentIntent(orderId);

      if (paymentResponse.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }

      return {
        'order_id': orderId,
        'client_secret': paymentResponse.data['client_secret'],
        'payment_id': paymentResponse.data['payment_id'],
      };
    } catch (e) {
      throw Exception('Error processing purchase: $e');
    }
  }

  Future<PaymentModel> confirmPayment({required int paymentId}) async {
    try {
      final response = await _apiService.confirmPayment(paymentId);

      if (response.statusCode == 200) {
        return PaymentModel(
          id: paymentId.toString(),
          orderId: '',
          userId: '',
          amount: 0,
          currency: 'usd',
          status: 'completed',
          paymentMethod: 'card',
          stripePaymentIntentId: '',
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
      } else {
        throw Exception('Failed to confirm payment');
      }
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }
}
