import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/data/repositories/payment_repo.dart';

class PaymentState {
  final List<PaymentModel> paymentHistory;
  final PaymentModel? currentPayment;
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;
  final String? successMessage;
  final bool paymentSuccess;

  PaymentState({
    this.paymentHistory = const [],
    this.currentPayment,
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
    this.successMessage,
    this.paymentSuccess = false,
  });

  PaymentState copyWith({
    List<PaymentModel>? paymentHistory,
    PaymentModel? currentPayment,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
    String? successMessage,
    bool? paymentSuccess,
  }) {
    return PaymentState(
      paymentHistory: paymentHistory ?? this.paymentHistory,
      currentPayment: currentPayment ?? this.currentPayment,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      successMessage: successMessage,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
    );
  }
}

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository _repository;

  PaymentCubit(this._repository) : super(PaymentState());

  // جلب سجل المدفوعات
  Future<void> getPaymentHistory({int page = 1}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final payments = await _repository.getPaymentHistory(page: page);
      emit(state.copyWith(paymentHistory: payments, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // ✅ إنشاء payment intent (يستخدم orderId من نوع int)
  Future<void> createPaymentIntent({
    required int orderId,
    required double amount,
  }) async {
    emit(state.copyWith(isProcessing: true, errorMessage: null));
    try {
      final payment = await _repository.createPaymentIntent(
        orderId: orderId,
        amount: amount,
      );
      emit(state.copyWith(currentPayment: payment, isProcessing: false));
    } catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.toString()));
    }
  }

  // ✅ تأكيد الدفع (يستخدم paymentId من نوع int)
  Future<void> confirmPayment({required int paymentId}) async {
    emit(state.copyWith(isProcessing: true, errorMessage: null));
    try {
      final payment = await _repository.confirmPayment(paymentId: paymentId);

      if (payment.status == 'completed') {
        emit(
          state.copyWith(
            currentPayment: payment,
            isProcessing: false,
            paymentSuccess: true,
            successMessage: 'تم الدفع بنجاح!',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isProcessing: false,
            errorMessage: 'فشل الدفع. الرجاء المحاولة مرة أخرى.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.toString()));
    }
  }

  // ✅ دالة مساعدة لشراء منتج مباشرة
  Future<Map<String, dynamic>?> purchaseProduct({
    required int buyerId,
    required int productId,
    required int quantity,
    String? shippingAddress,
  }) async {
    emit(state.copyWith(isProcessing: true, errorMessage: null));
    try {
      final result = await _repository.purchaseProduct(
        buyerId: buyerId,
        productId: productId,
        quantity: quantity,
        shippingAddress: shippingAddress,
      );

      emit(state.copyWith(isProcessing: false));
      return result;
    } catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.toString()));
      return null;
    }
  }

  // مسح الرسائل
  void clearMessages() {
    emit(
      state.copyWith(
        errorMessage: null,
        successMessage: null,
        paymentSuccess: false,
      ),
    );
  }

  // إعادة تعيين حالة الدفع
  void resetPaymentState() {
    emit(PaymentState());
  }
}
