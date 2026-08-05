import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;
  static const String baseUrl = 'http://10.219.48.75:8000/api/';
  static const String mediaUrl = 'http://10.219.48.75:8000';

  static const List<String> _publicEndpoints = [
    'products/approved/',
    'products/',
    'login/',
    'register/',
    'reviews/',
    //'cards/',
  ];

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) {
      return path
          .replaceAll('localhost', '10.219.48.75')
          .replaceAll('127.0.0.1', '10.219.48.75');
    }
    String cleanPath = path.startsWith('/') ? path : '/$path';
    if (!cleanPath.startsWith('/media/')) {
      cleanPath = '/media$cleanPath';
    }
    return '$mediaUrl$cleanPath';
  }

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getInt('user_id');
          final token = prefs.getString('access_token');

          final isPublic = _publicEndpoints.any(
            (ep) => options.path.contains(ep),
          );

          // ✅ أضف user_id إلى كل الطلبات غير العامة
          if (!isPublic && userId != null) {
            if (!options.queryParameters.containsKey('user_id')) {
              options.queryParameters['user_id'] = userId.toString();
            }
          }

          // ✅ أضف التوكن إذا وجد
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('📤 Request: ${options.method} ${options.uri}');
          print('📤 Query: ${options.queryParameters}');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 Response: ${response.statusCode} ${response.realUri}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error: ${error.message}');
          print('❌ Status: ${error.response?.statusCode}');
          print('❌ Data: ${error.response?.data}');

          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final options = error.requestOptions;
              final prefs = await SharedPreferences.getInstance();
              final newToken = prefs.getString('access_token');
              options.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {}
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;
      final response = await _dio.post(
        'token/refresh/',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200 && response.data['access_token'] != null) {
        await prefs.setString('access_token', response.data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== AUTH ====================
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      'login/',
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> register({
    required String full_name,
    required String email,
    required String password,
    String phone = '',
    String location = '', // ✅ أضف هذا
  }) async {
    return await _dio.post(
      'register/',
      data: {
        'full_name': full_name,
        'email': email,
        'password': password,
        'phone': phone,
        'location': location, // ✅ أرسل الموقع
      },
    );
  }

  // ==================== PRODUCTS ====================
  Future<Response> getApprovedProducts() async {
    return await _dio.get('products/', queryParameters: {'status': 'approved'});
  }

  Future<Response> getProducts({
    String? status,
    int? seller_id,
    String? category,
  }) async {
    return await _dio.get(
      'products/',
      queryParameters: {
        if (status != null) 'status': status,
        if (seller_id != null) 'seller_id': seller_id,
        if (category != null && category != 'الكل' && category != 'All')
          'category': category,
      },
    );
  }

  Future<Response> createProduct({
    required int seller_id,
    required String product_name,
    required double price,
    String? category,
    String? description,
    int stock = 0,
    String? imagePath,
  }) async {
    String? singleImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      singleImagePath = imagePath;
    }

    FormData formData = FormData.fromMap({
      'seller_id': seller_id,
      'product_name': product_name,
      'price': price,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      'stock': stock,
      if (singleImagePath != null && singleImagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(singleImagePath),
    });
    return await _dio.post('products/', data: formData);
  }

  Future<Response> getMyProducts(int seller_id) async {
    return await _dio.get(
      'products/',
      queryParameters: {'seller_id': seller_id},
    );
  }

  Future<Response> getProductDetails(String productId) async {
    return await _dio.get('products/$productId/');
  }

  Future<Response> searchProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? page,
  }) async {
    return await _dio.get(
      'products/',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'search': query,
        if (category != null && category != 'الكل' && category != 'All')
          'category': category,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (minRating != null) 'min_rating': minRating,
        if (page != null) 'page': page,
      },
    );
  }

  Future<Response> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    return await _dio.put(
      'products/$productId/',
      data: {
        'product_name': title,
        'description': description,
        'price': price,
        'category': category,
      },
    );
  }

  Future<Response> deleteProduct(String productId) async {
    return await _dio.delete('products/$productId/');
  }

  // ==================== ORDERS ====================
  Future<Response> createOrder({
    required int buyer_id,
    required int product_id,
    int quantity = 1,
    String? shipping_address,
  }) async {
    return await _dio.post(
      'orders/',
      data: {
        'buyer_id': buyer_id,
        'product_id': product_id,
        'quantity': quantity,
        if (shipping_address != null) 'shipping_address': shipping_address,
      },
    );
  }

  // ✅ FIX: Changed endpoint to match backend (Issue 6)
  Future<Response> getMyOrders(int buyer_id) async {
    return await _dio.get(
      'orders/my/',
      queryParameters: {'buyer_id': buyer_id},
    );
  }

  Future<Response> getSellerOrders(int seller_id) async {
    return await _dio.get(
      'orders/seller/',
      queryParameters: {'seller_id': seller_id},
    );
  }

  Future<Response> updateOrderStatus({
    required int order_id,
    required String status,
  }) async {
    return await _dio.post(
      'orders/status/',
      data: {'order_id': order_id, 'status': status},
    );
  }

  // ==================== PAYMENTS ====================
  Future<Response> createPaymentIntent(int order_id) async {
    return await _dio.post('payments/intent/', data: {'order_id': order_id});
  }

  Future<Response> confirmPayment(int payment_id) async {
    return await _dio.post(
      'payments/confirm/',
      data: {'payment_id': payment_id},
    );
  }

  // ==================== CARDS ====================
  // ✅ FIX: Updated endpoint to match backend (Issue 7)
  Future<Response> getSavedCards() async {
    return await _dio.get('cards/');
  }

  Future<Response> addCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
    required String cardType,
  }) async {
    return await _dio.post(
      'cards/',
      data: {
        'card_number': cardNumber,
        'expiry_date': expiryDate,
        'cvv': cvv,
        'cardholder_name': cardholderName,
        'card_type': cardType,
      },
    );
  }

  Future<Response> deleteCard(String cardId) async {
    return await _dio.delete('cards/$cardId/');
  }

  // ==================== WALLET ====================
  Future<Response> getBalance() async {
    return await _dio.get('wallet/balance/');
  }

  Future<Response> addBalance(double amount) async {
    return await _dio.post('wallet/topup/', data: {'amount': amount});
  }

  // ==================== NOTIFICATIONS ====================
  // ✅ FIX: Changed endpoint to match backend (Issue 5)
  Future<Response> getUserNotifications(int user_id) async {
    return await _dio.get(
      'notifications/user/',
      queryParameters: {'user_id': user_id},
    );
  }

  Future<Response> markNotificationAsRead(int notification_id) async {
    return await _dio.post(
      'notifications/read/',
      data: {'notification_id': notification_id},
    );
  }

  // ==================== USER ====================
  // ✅ FIX: Added token to headers for profile (Issue 4)
  Future<Response> getUserProfile(int user_id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return await _dio.get(
      'users/me/',
      queryParameters: {'user_id': user_id},
      options: Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<Response> updateUserProfile({
    required int user_id,
    String? full_name,
    String? phone,
    String? location,
    String? bio,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return await _dio.post(
      'users/update_profile/',
      data: {
        'user_id': user_id,
        if (full_name != null) 'full_name': full_name,
        if (phone != null) 'phone': phone,
        if (location != null) 'location': location,
        if (bio != null) 'bio': bio,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  // ==================== REVIEWS ====================
  // ✅ FIX: Changed endpoint to match backend (Issue 1)
  Future<Response> getMyReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return await _dio.get(
      'reviews/user/',
      queryParameters: {'user_id': userId},
    );
  }

  Future<Response> getProductReviews(String productId) async {
    return await _dio.get('reviews/product/$productId/');
  }

  Future<Response> createReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    return await _dio.post(
      'reviews/',
      data: {'product_id': productId, 'rating': rating, 'comment': comment},
    );
  }

  // ==================== CHAT ====================
  Future<Response> getActiveChats(int user_id) async {
    return await _dio.get(
      'chats/active/',
      queryParameters: {'user_id': user_id},
    );
  }

  Future<Response> startChat({
    required int sender_id,
    required int receiver_id,
    int? order_id,
  }) async {
    return await _dio.post(
      'chats/start/',
      data: {
        'sender_id': sender_id,
        'receiver_id': receiver_id,
        if (order_id != null) 'order_id': order_id,
      },
    );
  }

  Future<Response> sendMessage({
    required int chat_id,
    required int sender_id,
    required String content,
  }) async {
    return await _dio.post(
      'chats/message/',
      data: {'chat_id': chat_id, 'sender_id': sender_id, 'content': content},
    );
  }

  Future<Response> getMessageHistory(int chat_id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    return await _dio.get(
      'chats/history/',
      queryParameters: {
        'chat_id': chat_id,
        'user_id': userId, // ✅ أضف user_id
      },
    );
  }

  // ==================== HELPERS ====================
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userData['user_id']); // ✅ حفظ كـ int
    await prefs.setString('user_type', userData['user_type'] ?? 'buyer');
    await prefs.setString('full_name', userData['full_name'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('phone', userData['phone'] ?? '');
    await prefs.setString('location', userData['location'] ?? '');
    await prefs.setString('avatar', userData['avatar'] ?? '');
    await prefs.setString('bio', userData['bio'] ?? '');
    if (userData['access_token'] != null) {
      await prefs.setString('access_token', userData['access_token']);
    }
    if (userData['refresh_token'] != null) {
      await prefs.setString('refresh_token', userData['refresh_token']);
    }
    print('✅ Saved user_id: ${userData['user_id']}');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    return {
      'user_id': userId,
      'user_type': prefs.getString('user_type') ?? 'buyer',
      'full_name': prefs.getString('full_name') ?? '',
      'email': prefs.getString('email') ?? '',
      'phone': prefs.getString('phone') ?? '',
      'location': prefs.getString('location') ?? '',
      'avatar': prefs.getString('avatar') ?? '',
      'bio': prefs.getString('bio') ?? '',
      'access_token': prefs.getString('access_token'),
      'refresh_token': prefs.getString('refresh_token'),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
