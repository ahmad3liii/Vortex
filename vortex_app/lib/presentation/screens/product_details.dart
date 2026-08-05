import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/screens/home/seller_store_screen.dart';
import 'package:vortex_market/presentation/screens/chat/chat_screen.dart';
import 'package:vortex_market/logic/cubit/balance_cubit.dart';
import 'package:vortex_market/presentation/screens/profilee/payment_methods_screen.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map product;
  const ProductDetailsScreen({super.key, required this.product});

  int _getImageCount() {
    final imagesList = product['images'] as List?;
    if (imagesList != null && imagesList.isNotEmpty) {
      return imagesList.length;
    }
    final image = product['image'];
    if (image != null && image.toString().isNotEmpty) {
      return 1;
    }
    return 0;
  }

  String _getImageAtIndex(int index) {
    final imagesList = product['images'] as List?;
    if (imagesList != null &&
        imagesList.isNotEmpty &&
        index < imagesList.length) {
      return imagesList[index].toString();
    }
    return product['image']?.toString() ?? '';
  }

  String _getImageUrl(String? url) {
    print('🔍 Original URL: $url');
    if (url == null || url.isEmpty) {
      print('⚠️ URL is null or empty, using default');
      return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500';
    }
    if (url.startsWith('http')) {
      print('✅ URL is already valid: $url');
      return url;
    }
    if (url.startsWith('/media/')) {
      final fixed = 'http://10.219.48.75:8000$url';
      print('✅ Fixed media URL: $fixed');
      return fixed;
    }
    print('✅ Using URL as is: $url');
    return url;
  }

  void _openWhatsApp(String phone) async {
    final url =
        "https://wa.me/$phone?text=أنا مهتم بمنتجك: ${product['title']}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';
    final isDark = context.watch<ThemeCubit>().isDark;

    print('📦 Product Data:');
    print('   Title: ${product['title']}');
    print('   Image: ${product['image']}');
    print('   Images: ${product['images']}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: BackgroundWidget(
        child: Column(
          children: [
            // عرض صور المنتج بنمط Carousel
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Hero(
                    tag: product['id'],
                    child: PageView.builder(
                      itemCount: _getImageCount(),
                      itemBuilder: (context, index) {
                        final imageUrl = _getImageAtIndex(index);
                        print('🎯 Loading image $index: $imageUrl');

                        return Image.network(
                          _getImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.white10,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.blueAccent,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              '❌ Failed to load image: ${_getImageUrl(imageUrl)}',
                            );
                            print('   Error: $error');
                            return Container(
                              color: Colors.white10,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.broken_image,
                                    color: Colors.white30,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isEnglish
                                        ? 'Image not found'
                                        : 'الصورة غير متوفرة',
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_getImageCount() > 1)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isEnglish
                              ? "Swipe to see more ↔"
                              : "اسحب لرؤية المزيد ↔",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // تفاصيل المنتج
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(35),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product['title'] ?? '',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "\$${product['price']}",
                          style: TextStyle(
                            color: isDark ? Colors.blueAccent : Colors.purple,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // معلومات البائع
                    GestureDetector(
                      onTap: () {
                        final sellerProds = context
                            .read<ProductCubit>()
                            .state
                            .products
                            .where(
                              (p) =>
                                  p.sellerId ==
                                  product['seller']['id'].toString(),
                            )
                            .map(
                              (p) => {
                                'id': p.id,
                                'title': p.title,
                                'price': p.price,
                                'image': p.image,
                                'images': p.images,
                                'description': p.description,
                                'rating': p.rating,
                                'sellerPhone': p.sellerPhone,
                                'seller': {
                                  'id': p.sellerId,
                                  'name': p.sellerName,
                                  'avatar': p.sellerAvatar,
                                },
                              },
                            )
                            .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SellerStoreScreen(
                              sellerData: product['seller'],
                              sellerProducts: sellerProds,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(
                                _getImageUrl(product['seller']['avatar']),
                              ),
                              onBackgroundImageError: (_, __) {},
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${appLocalizations?.translate('seller') ?? 'البائع'}: ${product['seller']['name']}",
                              style: TextStyle(
                                color: isDark
                                    ? Colors.blueAccent
                                    : Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.storefront,
                              color: isDark ? Colors.blueAccent : Colors.purple,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    RatingBar.builder(
                      initialRating:
                          (product['rating'] as num?)?.toDouble() ?? 4.0,
                      itemSize: 20,
                      allowHalfRating: true,
                      unratedColor: Colors.white24,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {},
                    ),
                    const SizedBox(height: 20),
                    Text(
                      appLocalizations?.translate('description') ?? "الوصف",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'] ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),

                    // الأزرار
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    sellerName: product['seller']['name'],
                                    sellerId: product['seller']['id']
                                        .toString(),
                                  ),
                                ),
                              );
                            },
                            label: Text(
                              appLocalizations?.translate('direct_chat') ??
                                  "تواصل مباشر",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () =>
                              _openWhatsApp(product['sellerPhone']),
                          icon: const Icon(
                            Icons.phone_android,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.greenAccent,
                              size: 28,
                            ),
                            onPressed: () =>
                                _confirmPurchase(context, appLocalizations),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(
    BuildContext context,
    AppLocalizations? appLocalizations,
  ) {
    final productPrice = (product['price'] as num).toDouble();
    final balanceCubit = context.read<BalanceCubit>();

    showDialog(
      context: context,
      builder: (p) {
        return BlocBuilder<BalanceCubit, BalanceState>(
          builder: (context, state) {
            final cards = state.cards;
            CardModel? selectedCard = state.selectedCard;

            return AlertDialog(
              backgroundColor: const Color(0xFF161823),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.security,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations?.translate('confirm_purchase') ??
                        "تأكيد الدفع بالفيزا",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "أنت على وشك شراء منتج: ${product['title']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "المجموع الكلي:",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "\$${productPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (cards.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "لا توجد بطاقة دفع محفوظة! يرجى إضافة بطاقة ائتمانية للمتابعة.",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "اختر بطاقة الدفع:",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CardModel>(
                          value: selectedCard ?? cards.first,
                          dropdownColor: const Color(0xFF161823),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: cards.map((card) {
                            return DropdownMenuItem<CardModel>(
                              value: card,
                              child: Row(
                                children: [
                                  Icon(
                                    card.cardType.toLowerCase() == 'visa'
                                        ? Icons.credit_card
                                        : Icons.credit_card_sharp,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(card.cardNumber),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (card) {
                            if (card != null) balanceCubit.selectCard(card);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(p),
                  child: Text(
                    appLocalizations?.cancel ?? "إلغاء",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                if (cards.isEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_card, size: 18),
                    label: const Text("إضافة بطاقة دفع"),
                    onPressed: () {
                      Navigator.pop(p);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsScreen(),
                        ),
                      );
                    },
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(p);
                      _processPayment(context, balanceCubit, productPrice);
                    },
                    child: const Text("تأكيد ودفع بالبطاقة 💳"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _processPayment(
    BuildContext context,
    BalanceCubit balanceCubit,
    double price,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isProcessing = true;
            String message =
                "جاري الاتصال بالبنك ومعالجة عملية الدفع الآمنة...";

            Future.delayed(const Duration(milliseconds: 1500), () async {
              if (ctx.mounted && isProcessing) {
                setState(
                  () => message = "جاري إرسال العملية لشبكة Visa/Mastercard...",
                );

                final sellerId = product['seller']?['id']?.toString() ?? "s1";
                final sellerName = product['seller']?['name'] ?? "متجر التقنية";
                final success = await balanceCubit.purchaseProduct(
                  productPrice: price,
                  productId: product['id'].toString(),
                  productTitle: product['title'],
                  productImage: product['image'] ?? "",
                  sellerId: sellerId,
                  sellerName: sellerName,
                );

                if (ctx.mounted) {
                  setState(() {
                    isProcessing = false;
                    message = success
                        ? "تمت عملية الشراء بنجاح!"
                        : "فشلت عملية الدفع بالبطاقة";
                  });

                  Future.delayed(const Duration(milliseconds: 1200), () {
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? "تهانينا! تم الشراء بنجاح."
                                : "خطأ: لم نتمكن من خصم المبلغ من بطاقتك.",
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  });
                }
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF161823),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isProcessing)
                      const CircularProgressIndicator(color: Colors.blueAccent)
                    else
                      Icon(
                        message.contains("بنجاح")
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        color: message.contains("بنجاح")
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        size: 60,
                      ),
                    const SizedBox(height: 25),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
