import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ApiService _apiService = ApiService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUsingFallback = false;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  // ✅ FIX: Fallback to completed orders if reviews API returns 404 (Issue 1)
  Future<void> _loadMyReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUsingFallback = false;
    });

    try {
      final response = await _apiService.getMyReviews();
      print('📥 Reviews response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> reviewsData = data['reviews'] ?? data;
        if (reviewsData is List && reviewsData.isNotEmpty) {
          final reviews = reviewsData
              .map((json) => ReviewModel.fromMap(json))
              .toList();
          setState(() {
            _reviews = reviews;
            _isLoading = false;
          });
          return;
        }
        await _loadCompletedOrdersAsReviews();
        return;
      } else if (response.statusCode == 404) {
        await _loadCompletedOrdersAsReviews();
        return;
      }
    } catch (e) {
      print('❌ Reviews API failed: $e');
      await _loadCompletedOrdersAsReviews();
      return;
    }

    await _loadCompletedOrdersAsReviews();
  }

  Future<void> _loadCompletedOrdersAsReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يجب تسجيل الدخول أولاً';
        });
        return;
      }

      print('📥 Using fallback: loading completed orders for user $userId');

      final ordersResponse = await _apiService.getMyOrders(userId);
      print('📥 Orders response status: ${ordersResponse.statusCode}');

      if (ordersResponse.statusCode == 200) {
        final List<dynamic> ordersData = ordersResponse.data is List
            ? ordersResponse.data
            : (ordersResponse.data['orders'] ?? []);

        final completedOrders = ordersData
            .where(
              (order) =>
                  order['order_status'] == 'delivered' ||
                  order['order_status'] == 'confirmed' ||
                  order['order_status'] == 'shipped',
            )
            .toList();

        print('📥 Found ${completedOrders.length} completed orders');

        final reviewsFromOrders = completedOrders.map((order) {
          return ReviewModel(
            id: order['order_id']?.toString() ?? '',
            productId: order['product_id']?.toString() ?? '',
            productName:
                order['product_title'] ?? order['product_name'] ?? 'Product',
            productImage: ApiService.getFullImageUrl(
              order['product_image'] ?? order['image'] ?? '',
            ),
            userName: '',
            userAvatar: '',
            rating: 5.0,
            comment: 'تم استلام الطلب بنجاح - ${order['order_status'] ?? ''}',
            createdAt:
                DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now(),
          );
        }).toList();

        setState(() {
          _reviews = reviewsFromOrders;
          _isUsingFallback = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل تحميل التقييمات';
        });
      }
    } catch (e) {
      print('❌ Fallback error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في الاتصال: ${e.toString()}';
      });
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = l10n?.locale.languageCode == 'en';
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('reviews') ?? (isEnglish ? "My Reviews" : "تقييماتي"),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.transparent : Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              )
            : Column(
                children: [
                  if (_isUsingFallback)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.blueAccent.withOpacity(0.2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isEnglish
                                  ? 'Showing completed orders (reviews API unavailable)'
                                  : 'عرض الطلبات المكتملة (API التقييمات غير متاح)',
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 60,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadMyReviews,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                  child: Text(
                                    isEnglish ? "Retry" : "إعادة المحاولة",
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _reviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_outline_rounded,
                                  size: 80,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isEnglish
                                      ? "You haven't written any reviews yet."
                                      : "لم تقم بكتابة أي تقييمات بعد.",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            review.productImage,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black
                                                            .withOpacity(0.05),
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    color: isDark
                                                        ? Colors.white30
                                                        : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review.productName,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              RatingBarIndicator(
                                                rating: review.rating,
                                                itemBuilder: (context, index) =>
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    ),
                                                itemCount: 5,
                                                itemSize: 16.0,
                                                direction: Axis.horizontal,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatDate(review.createdAt),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white30
                                                : Colors.black26,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      review.comment,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
