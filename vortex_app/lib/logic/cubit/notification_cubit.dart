import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/services/api_service.dart';

class NotificationCubit extends Cubit<List<NotificationModel>> {
  final ApiService _apiService = ApiService();

  NotificationCubit() : super([]) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final response = await _apiService.getUserNotifications(userId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['notifications'] ?? []);
        final notifications = data
            .map((json) => NotificationModel.fromMap(json))
            .toList();
        emit(notifications);
      }
    } catch (e) {
      emit([]);
    }
  }

  void add(NotificationModel n) {
    // في التطبيق الحقيقي، سيتم إرسال الإشعار عبر WebSocket أو دالة خاصة
    // حالياً نضيفه محلياً فقط
    final currentList = List<NotificationModel>.from(state);
    currentList.insert(0, n);
    emit(currentList);
  }

  void clearNotifications() {
    emit([]);
  }

  void clear() => clearNotifications();

  // دوال مساعدة لإضافة إشعارات محاكاة (يمكن تعديلها لاستدعاء API حقيقي)
  void notifyProductUploaded(String productTitle) {
    add(
      NotificationModel(
        id: 'notif_upload_${DateTime.now().millisecondsSinceEpoch}',
        title: 'تم نشر منتجك بنجاح 🎉',
        message:
            'منتجك "$productTitle" أصبح مرئياً الآن في السوق وجاهزاً للبيع!',
        timestamp: DateTime.now(),
      ),
    );
  }

  void notifyNewMessage(String senderName) {
    add(
      NotificationModel(
        id: 'notif_msg_${DateTime.now().millisecondsSinceEpoch}',
        title: 'رسالة جديدة 💬',
        message: 'أرسل لك $senderName رسالة جديدة. اضغط للرد.',
        timestamp: DateTime.now(),
      ),
    );
  }

  void notifyNewOrder(String productTitle, String buyerName) {
    add(
      NotificationModel(
        id: 'notif_order_${DateTime.now().millisecondsSinceEpoch}',
        title: 'طلب شراء جديد 🛒',
        message:
            'اشترى $buyerName منتجك "$productTitle" - تحقق من طلبات البيع.',
        timestamp: DateTime.now(),
      ),
    );
  }

  void notifyNewProductInMarket(String productTitle) {
    add(
      NotificationModel(
        id: 'notif_market_${DateTime.now().millisecondsSinceEpoch}',
        title: 'منتج جديد في السوق 🛍️',
        message: '"$productTitle" أُضيف للتو إلى السوق. لا تفوّت الفرصة!',
        timestamp: DateTime.now(),
      ),
    );
  }
}
