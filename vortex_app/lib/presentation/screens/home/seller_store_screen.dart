import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';
import '../../widgets/product_card.dart';

class SellerStoreScreen extends StatelessWidget {
  final Map sellerData;
  final List sellerProducts;

  const SellerStoreScreen({
    super.key,
    required this.sellerData,
    required this.sellerProducts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight + 40),

            _buildStoreHeader(isDark),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n?.translate('all_products') ?? "جميع المنتجات",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: sellerProducts.isEmpty
                  ? _buildEmptyState(isDark)
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                          ),
                      itemCount: sellerProducts.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: sellerProducts[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          // صورة البائع مع حدود مضيئة
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(sellerData['avatar']),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerData['name'],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "بائع موثوق • ${sellerProducts.length} منتج",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              foregroundColor: Colors.blueAccent,
              elevation: 0,
              side: const BorderSide(color: Colors.blueAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "متابعة",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.inventory_2_outlined,
          color: isDark ? Colors.white24 : Colors.black26,
          size: 80,
        ),
        const SizedBox(height: 15),
        Text(
          "هذا البائع ليس لديه منتجات حالياً",
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
