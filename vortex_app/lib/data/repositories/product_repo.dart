import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/data/models/app_models.dart';

class ProductRepository {
  final ApiService _apiService = ApiService();

  Future<List<ProductModel>> getApprovedProducts() async {
    try {
      final response = await _apiService.getApprovedProducts();
      if (response.statusCode == 200) {
        final productsList = _extractListFromResponse(response.data);
        return productsList.map((json) => ProductModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ getApprovedProducts error: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getProducts({
    String? category,
    int? sellerId,
  }) async {
    try {
      final response = await _apiService.getProducts(
        status: 'approved',
        seller_id: sellerId,
        category: category,
      );
      if (response.statusCode == 200) {
        final productsList = _extractListFromResponse(response.data);
        return productsList.map((json) => ProductModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ getProducts error: $e');
      return [];
    }
  }

  Future<List<ProductModel>> getMyProducts(int sellerId) async {
    try {
      final response = await _apiService.getMyProducts(sellerId);
      if (response.statusCode == 200) {
        final productsList = _extractListFromResponse(response.data);
        return productsList.map((json) => ProductModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ getMyProducts error: $e');
      return [];
    }
  }

  Future<ProductModel?> getProductById(int productId) async {
    try {
      final response = await _apiService.getProductDetails(
        productId.toString(),
      );
      if (response.statusCode == 200) {
        return ProductModel.fromMap(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ getProductById error: $e');
      return null;
    }
  }

  // ✅ تحسين: التأكد من أن imagePath هو String وليس List
  Future<bool> uploadProduct({
    required int sellerId,
    required String title,
    required double price,
    required String description,
    required String category,
    required String imagePath,
  }) async {
    try {
      // ✅ التأكد من أن imagePath ليس فارغاً
      if (imagePath.isEmpty) {
        print('❌ imagePath is empty');
        return false;
      }

      final response = await _apiService.createProduct(
        seller_id: sellerId,
        product_name: title,
        price: price,
        category: category,
        description: description,
        imagePath: imagePath, // ✅ مباشرة بدون .first
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('❌ uploadProduct error: $e');
      return false;
    }
  }

  Future<bool> updateProduct({
    required int productId,
    required String title,
    required double price,
    required String description,
    required String category,
  }) async {
    try {
      final response = await _apiService.updateProduct(
        productId: productId.toString(),
        title: title,
        description: description,
        price: price,
        category: category,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ updateProduct error: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await _apiService.deleteProduct(productId.toString());
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ deleteProduct error: $e');
      return false;
    }
  }

  Future<List<ProductModel>> searchProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      final response = await _apiService.searchProducts(
        query: query,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
      );
      if (response.statusCode == 200) {
        final productsList = _extractListFromResponse(response.data);
        return productsList.map((json) => ProductModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ searchProducts error: $e');
      return [];
    }
  }

  Future<List<ReviewModel>> getProductReviews(int productId) async {
    try {
      final response = await _apiService.getProductReviews(
        productId.toString(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => ReviewModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ getProductReviews error: $e');
      return [];
    }
  }

  Future<bool> addReview({
    required int productId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _apiService.createReview(
        productId: productId.toString(),
        rating: rating,
        comment: comment,
      );
      return response.statusCode == 201;
    } catch (e) {
      print('❌ addReview error: $e');
      return false;
    }
  }

  List<dynamic> _extractListFromResponse(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      // البحث عن مفتاح يحوي قائمة
      const possibleKeys = [
        'results',
        'products',
        'data',
        'items',
        'product_list',
        'list',
      ];
      for (final key in possibleKeys) {
        if (data.containsKey(key) && data[key] is List) {
          return data[key] as List;
        }
      }
      // إذا كان الكائن نفسه يحوي معرف المنتج، نعتبره منتجاً واحداً
      if (data.containsKey('product_id') || data.containsKey('id')) {
        return [data];
      }
      return [];
    }
    return [];
  }
}
