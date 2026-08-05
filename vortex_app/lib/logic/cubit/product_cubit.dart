import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/data/repositories/product_repo.dart';
import 'package:vortex_market/logic/services/api_service.dart';

class ProductState {
  final List<ProductModel> products;
  final List<ProductModel> filteredProducts;
  final List<ProductModel> myProducts;
  final bool isLoading;
  final bool isUploading;
  final bool isUploadSuccess;
  final String? errorMessage;
  final String selectedCategory;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? searchQuery;
  final String? sortBy;

  ProductState({
    this.products = const [],
    this.filteredProducts = const [],
    this.myProducts = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isUploadSuccess = false,
    this.errorMessage,
    this.selectedCategory = "الكل",
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.searchQuery,
    this.sortBy,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? filteredProducts,
    List<ProductModel>? myProducts,
    bool? isLoading,
    bool? isUploading,
    bool? isUploadSuccess,
    String? errorMessage,
    String? selectedCategory,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? searchQuery,
    String? sortBy,
  }) {
    return ProductState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      myProducts: myProducts ?? this.myProducts,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isUploadSuccess: isUploadSuccess ?? this.isUploadSuccess,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository = ProductRepository();

  ProductCubit() : super(ProductState());

  Future<void> initialize() async {
    await fetchProducts();
  }

  Future<void> refreshProducts() async {
    await fetchProducts();
    await fetchMyProducts();
  }

  Future<void> fetchProducts() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final list = await _productRepository.getApprovedProducts();
      emit(
        state.copyWith(
          products: list,
          filteredProducts: list,
          isLoading: false,
        ),
      );
      await fetchMyProducts();
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: "تعذر تحميل المنتجات"),
      );
    }
  }

  Future<void> fetchProductsByCategory(String category) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final list = await _productRepository.getProducts(category: category);
      emit(
        state.copyWith(
          products: list,
          filteredProducts: list,
          selectedCategory: category,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: "تعذر تحميل المنتجات"),
      );
    }
  }

  Future<void> fetchMyProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getInt('user_id');
      if (sellerId != null) {
        final list = await _productRepository.getMyProducts(sellerId);
        emit(state.copyWith(myProducts: list));
      } else {
        emit(state.copyWith(myProducts: []));
      }
    } catch (e) {
      emit(state.copyWith(myProducts: []));
    }
  }

  Future<void> applyFilters({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final results = await _productRepository.searchProducts(
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
      );
      emit(
        state.copyWith(
          filteredProducts: results,
          selectedCategory: category ?? state.selectedCategory,
          minPrice: minPrice ?? state.minPrice,
          maxPrice: maxPrice ?? state.maxPrice,
          minRating: minRating ?? state.minRating,
          isLoading: false,
        ),
      );
    } catch (e) {
      // If server-side fails, fall back to local filtering
      List<ProductModel> filtered = List.from(state.products);
      if (category != null && category != "الكل" && category != "All") {
        filtered = filtered.where((p) => p.category == category).toList();
      }
      if (minPrice != null) {
        filtered = filtered.where((p) => p.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        filtered = filtered.where((p) => p.price <= maxPrice).toList();
      }
      if (minRating != null) {
        filtered = filtered.where((p) => p.rating >= minRating).toList();
      }
      emit(
        state.copyWith(
          filteredProducts: filtered,
          selectedCategory: category ?? state.selectedCategory,
          minPrice: minPrice ?? state.minPrice,
          maxPrice: maxPrice ?? state.maxPrice,
          minRating: minRating ?? state.minRating,
          isLoading: false,
        ),
      );
    }
  }

  void sortProducts(String sortBy) {
    List<ProductModel> sorted = List.from(state.filteredProducts);
    switch (sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        sorted = sorted.reversed.toList();
        break;
    }
    emit(state.copyWith(filteredProducts: sorted, sortBy: sortBy));
  }

  void filterProducts(String category) {
    fetchProductsByCategory(category);
  }

  Future<void> searchProducts(String query) async {
    emit(state.copyWith(searchQuery: query, isLoading: true));
    try {
      final results = await _productRepository.searchProducts(query: query);
      emit(state.copyWith(filteredProducts: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "فشل البحث"));
    }
  }

  // Future<bool> uploadProduct({
  //   required String title,
  //   required double price,
  //   required String description,
  //   required String category,
  //   required String imagePath,
  // }) async {
  //   // Validate imagePath
  //   if (imagePath.isEmpty) {
  //     emit(
  //       state.copyWith(
  //         isUploading: false,
  //         errorMessage: "مسار الصورة غير صالح",
  //       ),
  //     );
  //     return false;
  //   }

  //   emit(
  //     state.copyWith(
  //       isUploading: true,
  //       isUploadSuccess: false,
  //       errorMessage: null,
  //     ),
  //   );
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final sellerId = prefs.getInt('user_id');
  //     if (sellerId == null) {
  //       emit(
  //         state.copyWith(
  //           isUploading: false,
  //           errorMessage: "يجب تسجيل الدخول أولاً",
  //         ),
  //       );
  //       return false;
  //     }

  //     // Log the upload attempt
  //     print('Uploading product with image: $imagePath');

  //     final success = await _productRepository.uploadProduct(
  //       sellerId: sellerId,
  //       title: title,
  //       price: price,
  //       description: description,
  //       category: category,
  //       imagePath: imagePath,
  //     );

  //     if (success) {
  //       emit(state.copyWith(isUploading: false, isUploadSuccess: true));
  //       await refreshProducts();
  //       return true;
  //     } else {
  //       emit(
  //         state.copyWith(isUploading: false, errorMessage: "فشل إرسال المنتج - تأكد من صيغة البيانات"),
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     print('Upload error: $e');
  //     emit(
  //       state.copyWith(
  //         isUploading: false,
  //         errorMessage: "فشل إرسال المنتج: $e",
  //       ),
  //     );
  //     return false;
  //   }
  // }

  // ✅ FIX: Ensure imagePath is a single String (Issue 3)
  Future<bool> uploadProduct({
    required String title,
    required double price,
    required String description,
    required String category,
    required String imagePath, // ✅ Single String, not List<String>
  }) async {
    // Validate imagePath
    if (imagePath.isEmpty) {
      emit(
        state.copyWith(
          isUploading: false,
          errorMessage: "مسار الصورة غير صالح",
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        isUploading: true,
        isUploadSuccess: false,
        errorMessage: null,
      ),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final sellerId = prefs.getInt('user_id');
      if (sellerId == null) {
        emit(
          state.copyWith(
            isUploading: false,
            errorMessage: "يجب تسجيل الدخول أولاً",
          ),
        );
        return false;
      }

      // ✅ Log the upload
      print('📤 Uploading product with image: $imagePath');

      final success = await _productRepository.uploadProduct(
        sellerId: sellerId,
        title: title,
        price: price,
        description: description,
        category: category,
        imagePath: imagePath, // ✅ Single String
      );

      if (success) {
        emit(state.copyWith(isUploading: false, isUploadSuccess: true));
        await refreshProducts();
        return true;
      } else {
        emit(
          state.copyWith(
            isUploading: false,
            errorMessage: "فشل إرسال المنتج - تأكد من صيغة البيانات",
          ),
        );
        return false;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      emit(
        state.copyWith(
          isUploading: false,
          errorMessage: "فشل إرسال المنتج: $e",
        ),
      );
      return false;
    }
  }

  void clearFilters() {
    emit(
      state.copyWith(
        filteredProducts: state.products,
        minPrice: null,
        maxPrice: null,
        minRating: null,
        searchQuery: null,
        sortBy: null,
        selectedCategory: "الكل",
      ),
    );
  }

  void resetUploadStatus() {
    emit(state.copyWith(isUploadSuccess: false));
  }
}
