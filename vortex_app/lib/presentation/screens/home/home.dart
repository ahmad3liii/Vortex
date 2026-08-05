import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/presentation/screens/product_details.dart';
import 'package:vortex_market/presentation/screens/product_filter_screen.dart';
import 'package:vortex_market/presentation/screens/upload_product_screen.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await context.read<ProductCubit>().fetchProducts();
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await context.read<ProductCubit>().fetchProducts();
    }
  }

  List<String> getCategories(BuildContext context) {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';
    if (isEnglish) {
      return [
        "All",
        "Clothing",
        "Accessories",
        "Smart Devices",
        "Furniture",
        "Groceries",
      ];
    } else {
      return [
        "الكل",
        "ملابس",
        "إكسسوارات",
        "أجهزة ذكية",
        "أثاث",
        "مواد غذائية",
      ];
    }
  }

  String _mapCategoryToFilter(String category, bool isEnglish) {
    if (category == "All" || category == "الكل") return "الكل";
    if (isEnglish) {
      switch (category) {
        case "Clothing":
          return "ملابس";
        case "Accessories":
          return "إكسسوارات";
        case "Smart Devices":
          return "أجهزة ذكية";
        case "Furniture":
          return "أثاث";
        case "Groceries":
          return "مواد غذائية";
        default:
          return category;
      }
    }
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final categories = getCategories(context);
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFA855F7),
      backgroundColor: const Color(0xFF1A1A2E),
      child: BackgroundWidget(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 70),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.sp),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductFilterScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.sp),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(10.sp),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune,
                                color: const Color(0xFFA855F7),
                                size: 18.sp,
                              ),
                              SizedBox(width: 6.sp),
                              Text(
                                isEnglish ? 'Filters' : 'فلاتر',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UploadProductScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.sp),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B39A0), Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              SizedBox(width: 6.sp),
                              Text(
                                isEnglish ? 'Sell' : 'بيع',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.sp),
                BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    return _buildCategoryBar(
                      categories,
                      state.selectedCategory,
                      isEnglish,
                    );
                  },
                ),
                Expanded(
                  child: BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, state) {
                      if (state.isLoading && !_isRefreshing) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA855F7),
                          ),
                        );
                      }

                      if (state.errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 50.sp,
                                color: Colors.redAccent,
                              ),
                              SizedBox(height: 10.sp),
                              Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20.sp),
                              ElevatedButton(
                                onPressed: _onRefresh,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA855F7),
                                ),
                                child: Text(
                                  isEnglish ? 'Retry' : 'إعادة المحاولة',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final products = state.filteredProducts;

                      if (products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80.sp,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              SizedBox(height: 16.sp),
                              Text(
                                isEnglish
                                    ? "No products available"
                                    : "لا يوجد منتجات متاحة حالياً",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 20.sp),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UploadProductScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: Text(
                                  isEnglish ? "Add Product" : "أضف منتج",
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA855F7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return AnimationLimiter(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 90),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 500),
                              columnCount: 2,
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: _buildProductCard(
                                    product,
                                    appLocalizations,
                                    isEnglish,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isRefreshing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFA855F7),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(
    List<String> categories,
    String selectedCat,
    bool isEnglish,
  ) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final catLabel = categories[i];
          bool active = false;
          if (isEnglish) {
            active = _mapCategoryToFilter(catLabel, true) == selectedCat;
          } else {
            active = catLabel == selectedCat;
          }

          return GestureDetector(
            onTap: () {
              final mappedCat = _mapCategoryToFilter(catLabel, isEnglish);
              context.read<ProductCubit>().filterProducts(mappedCat);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF5B39A0), Color(0xFFA855F7)],
                      )
                    : null,
                color: active ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? const Color(0xFFA855F7) : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  catLabel,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white60,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    ProductModel product,
    AppLocalizations? appLocalizations,
    bool isEnglish,
  ) {
    final productMap = {
      'id': product.id,
      'title': product.title,
      'price': product.price,
      'image': product.image,
      'images': product.images,
      'description': product.description,
      'rating': product.rating,
      'sellerPhone': product.sellerPhone,
      'seller': {
        'id': product.sellerId,
        'name': product.sellerName,
        'avatar': product.sellerAvatar,
      },
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: productMap),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: product.id,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white10,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${product.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFA855F7),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                          Text(
                            " ${product.rating}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
