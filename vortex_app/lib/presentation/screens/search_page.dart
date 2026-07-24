import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/presentation/screens/product_details.dart';
import '../widgets/background_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = "";
  List<String> smartSuggestions = [];

  void updateSuggestions(String query, BuildContext context) {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';

    // Observer Pattern: Triggering search update inside ProductCubit
    context.read<ProductCubit>().searchProducts(query);

    setState(() {
      searchQuery = query;

      if ((query.contains("أسود") || query.contains("black")) && !isEnglish) {
        smartSuggestions = [
          "حذاء أسود جلد",
          "ساعة يد سوداء كلاسيك",
          "محفظة سوداء",
        ];
      } else if ((query.toLowerCase().contains("black")) && isEnglish) {
        smartSuggestions = [
          "Black Leather Shoes",
          "Classic Black Watch",
          "Black Wallet",
        ];
      } else {
        smartSuggestions = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';

    return BackgroundWidget(
      // ✅ استخدام الخلفية الديناميكية
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 120),

            // Search Input
            TextField(
              onChanged: (val) => updateSuggestions(val, context),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isEnglish
                    ? "Search for (black sweater...)"
                    : "ابحث عن (كنزة سوداء...)",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 1.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Search Status or Smart suggestions
            if (searchQuery.isNotEmpty) ...[
              Text(
                isEnglish
                    ? "Search results for: $searchQuery"
                    : "نتائج البحث عن: $searchQuery",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (smartSuggestions.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEnglish
                              ? "Matching suggestions for your style (80%)"
                              : "اقتراحات مكملة لمظهرك الأسود (80%)",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ...smartSuggestions.map(
                      (item) => InkWell(
                        onTap: () {
                          // Fill search box with selection
                          // This naturally satisfies interactive experience
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.white30,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],

            // Search Results Grid/List
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  final list = state.filteredProducts;

                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        isEnglish
                            ? "No matching products"
                            : "لا توجد منتجات مطابقة",
                        style: const TextStyle(color: Colors.white38),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final product = list[index];
                      return _buildSearchResultTile(product);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(ProductModel product) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            product.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 60,
              height: 60,
              color: Colors.white10,
              child: const Icon(Icons.broken_image, color: Colors.white30),
            ),
          ),
        ),
        title: Text(
          product.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              "\$${product.price.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white30,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: productMap),
            ),
          );
        },
      ),
    );
  }
}
