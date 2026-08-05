import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/services/api_service.dart';

class BalanceState {
  final double balance;
  final bool isLoading;
  final String? errorMessage;
  final bool isPurchaseSuccess;
  final List<CardModel> cards;
  final CardModel? selectedCard;

  BalanceState({
    this.balance = 0.0,
    this.isLoading = false,
    this.errorMessage,
    this.isPurchaseSuccess = false,
    this.cards = const [],
    this.selectedCard,
  });

  BalanceState copyWith({
    double? balance,
    bool? isLoading,
    String? errorMessage,
    bool? isPurchaseSuccess,
    List<CardModel>? cards,
    CardModel? selectedCard,
    bool clearSelectedCard = false,
  }) {
    return BalanceState(
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isPurchaseSuccess: isPurchaseSuccess ?? this.isPurchaseSuccess,
      cards: cards ?? this.cards,
      selectedCard: clearSelectedCard
          ? null
          : (selectedCard ?? this.selectedCard),
    );
  }
}

class BalanceCubit extends Cubit<BalanceState> {
  final ApiService _apiService = ApiService();

  BalanceCubit() : super(BalanceState()) {
    loadBalance();
    loadCards();
  }

  Future<void> loadBalance() async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        // يمكن جلب الرصيد من API إذا كان متاحاً
        // حالياً نستخدم قيمة افتراضية
        emit(state.copyWith(balance: 0.0, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "فشل تحميل الرصيد"));
    }
  }

  Future<void> addBalance(double amount) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _apiService.addBalance(amount);
      if (response.statusCode == 200) {
        final newBalance = (response.data['balance'] as num).toDouble();
        emit(state.copyWith(balance: newBalance, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: "فشل شحن الرصيد"));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "خطأ في الاتصال"));
    }
  }

  Future<void> loadCards() async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await _apiService.getSavedCards();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['cards'] ?? []);
        final cards = data.map((json) => CardModel.fromMap(json)).toList();
        emit(
          state.copyWith(
            cards: cards,
            selectedCard: cards.isNotEmpty ? cards.first : null,
            isLoading: false,
          ),
        );
      } else {
        emit(state.copyWith(cards: [], isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(cards: [], isLoading: false));
    }
  }

  void selectCard(CardModel card) {
    emit(state.copyWith(selectedCard: card));
  }

  Future<bool> addCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
    required String cardType,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final response = await _apiService.addCard(
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        cardholderName: cardholderName,
        cardType: cardType,
      );
      if (response.statusCode == 201) {
        await loadCards();
        return true;
      } else {
        emit(
          state.copyWith(isLoading: false, errorMessage: "فشلت إضافة البطاقة"),
        );
        return false;
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "خطأ في الاتصال"));
      return false;
    }
  }

  Future<void> deleteCard(String cardId) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _apiService.deleteCard(cardId);
      await loadCards();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "فشل حذف البطاقة"));
    }
  }

  Future<bool> purchaseProduct({
    required double productPrice,
    required String productId,
    required String productTitle,
    String? productImage,
    String? sellerId,
    String? sellerName,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final prefs = await SharedPreferences.getInstance();
      final buyerId = prefs.getInt('user_id');
      if (buyerId == null) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "يجب تسجيل الدخول أولاً",
          ),
        );
        return false;
      }

      // إنشاء طلب جديد
      final orderResponse = await _apiService.createOrder(
        buyer_id: buyerId,
        product_id: int.parse(productId),
        quantity: 1,
      );

      if (orderResponse.statusCode != 201) {
        emit(state.copyWith(isLoading: false, errorMessage: "فشل إنشاء الطلب"));
        return false;
      }

      final orderData = orderResponse.data;
      final orderId = orderData['order_id'];

      // إنشاء payment intent
      final paymentResponse = await _apiService.createPaymentIntent(orderId);
      if (paymentResponse.statusCode != 200) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "فشل إنشاء عملية الدفع",
          ),
        );
        return false;
      }

      // تأكيد الدفع
      final paymentId = paymentResponse.data['payment_id'];
      final confirmResponse = await _apiService.confirmPayment(paymentId);

      if (confirmResponse.statusCode == 200) {
        emit(state.copyWith(isLoading: false, isPurchaseSuccess: true));
        Future.delayed(const Duration(seconds: 2), () {
          emit(state.copyWith(isPurchaseSuccess: false));
        });
        return true;
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: "فشل الدفع"));
        return false;
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "فشل في إتمام عملية الشراء",
        ),
      );
      return false;
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
