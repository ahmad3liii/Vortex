import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/services/api_service.dart';

class OrderState {
  final List<OrderModel> orders;
  final List<OrderModel> myPurchases;
  final List<OrderModel> salesOrders;
  final bool isLoading;
  final String? errorMessage;

  OrderState({
    this.orders = const [],
    this.myPurchases = const [],
    this.salesOrders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? myPurchases,
    List<OrderModel>? salesOrders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      myPurchases: myPurchases ?? this.myPurchases,
      salesOrders: salesOrders ?? this.salesOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OrderCubit extends Cubit<OrderState> {
  final ApiService _apiService = ApiService();

  OrderCubit() : super(OrderState());

  Future<void> fetchOrders() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        emit(
          state.copyWith(isLoading: false, errorMessage: "يجب تسجيل الدخول"),
        );
        return;
      }

      // جلب مشترياتي (كـ مشتري)
      final purchasesResponse = await _apiService.getMyOrders(userId);
      List<OrderModel> myPurchases = [];
      if (purchasesResponse.statusCode == 200) {
        final List<dynamic> data = purchasesResponse.data is List
            ? purchasesResponse.data
            : (purchasesResponse.data['orders'] ?? []);
        myPurchases = data.map((json) => OrderModel.fromMap(json)).toList();
      }

      // جلب طلبات البيع (كـ بائع)
      final salesResponse = await _apiService.getSellerOrders(userId);
      List<OrderModel> salesOrders = [];
      if (salesResponse.statusCode == 200) {
        final List<dynamic> data = salesResponse.data is List
            ? salesResponse.data
            : (salesResponse.data['orders'] ?? []);
        salesOrders = data.map((json) => OrderModel.fromMap(json)).toList();
      }

      emit(
        state.copyWith(
          myPurchases: myPurchases,
          salesOrders: salesOrders,
          orders: [...myPurchases, ...salesOrders],
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: "تعذر تحميل الطلبات"),
      );
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      String backendStatus;
      switch (newStatus) {
        case 'processing':
          backendStatus = 'confirmed';
          break;
        case 'shipped':
          backendStatus = 'shipped';
          break;
        case 'delivered':
          backendStatus = 'delivered';
          break;
        case 'cancelled':
          backendStatus = 'cancelled';
          break;
        default:
          backendStatus = newStatus;
      }

      final response = await _apiService.updateOrderStatus(
        order_id: orderId,
        status: backendStatus,
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "فشل تحديث حالة الطلب",
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "حدث خطأ أثناء تحديث حالة الطلب",
        ),
      );
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(int.parse(orderId), 'cancelled');
  }
}
