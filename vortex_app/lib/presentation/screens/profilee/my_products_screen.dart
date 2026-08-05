import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/logic/cubit/notification_cubit.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    print('🔄 Loading my products...');

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    print('👤 Current user_id: $userId');

    if (userId == null) {
      print('⚠️ No user_id found! User may not be logged in.');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    if (mounted) {
      try {
        await context.read<ProductCubit>().fetchMyProducts();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في جلب البيانات: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
      }
    }
  }

  File? _pickedImage;
  final _picker = ImagePicker();

  String _getImageUrl(String? url) {
    return ApiService.getFullImageUrl(url);
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.blueAccent,
              ),
              title: const Text(
                'التقاط صورة بالكاميرا',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Colors.purple,
              ),
              title: const Text(
                'اختيار من المعرض',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );

    if (picked != null) {
      setModalState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  void _showAddProductBottomSheet(BuildContext context) {
    print('🟢 _showAddProductBottomSheet called');

    // ✅ استخدام read بدلاً من watch لتجنب خطأ الاستماع خارج شجرة الـ Widget
    final isDark = context.read<ThemeCubit>().isDark;
    final l10n = AppLocalizations.of(context);

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'أجهزة ذكية';
    _pickedImage = null;

    final categories = [
      'أجهزة ذكية',
      'ملابس',
      'إكسسوارات',
      'أثاث',
      'مواد غذائية',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161823) : Colors.grey.shade200,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        l10n?.translate('add_product_title') ??
                            'إضافة منتج جديد للبيع',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => _pickImage(setModalState),
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _pickedImage != null
                                  ? Colors.blueAccent
                                  : (isDark ? Colors.white24 : Colors.black26),
                              width: 1.5,
                            ),
                          ),
                          child: _pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _pickedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_rounded,
                                      size: 45,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n?.translate('tap_to_add_image') ??
                                          'اضغط لإضافة صورة المنتج',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n?.translate(
                                            'from_camera_or_gallery',
                                          ) ??
                                          'من الكاميرا أو المعرض',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white30
                                            : Colors.black38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: titleController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          l10n?.translate('product_name') ?? 'اسم المنتج',
                          Icons.shopping_bag_outlined,
                          isDark,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? (l10n?.translate('required_field') ??
                                  'الحقل مطلوب')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          l10n?.translate('price_usd') ?? 'السعر بالدولار',
                          Icons.attach_money,
                          isDark,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return l10n?.translate('required_field') ??
                                'الحقل مطلوب';
                          if (double.tryParse(v) == null)
                            return l10n?.translate('enter_valid_number') ??
                                'أدخل رقم صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        dropdownColor: isDark
                            ? const Color(0xFF1A1D2E)
                            : Colors.grey.shade200,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          l10n?.translate('category') ?? 'الفئة',
                          Icons.category_outlined,
                          isDark,
                        ),
                        items: categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) selectedCategory = val;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          l10n?.translate('product_description') ??
                              'وصف المنتج بالتفصيل',
                          Icons.description_outlined,
                          isDark,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? (l10n?.translate('required_field') ??
                                  'الحقل مطلوب')
                            : null,
                      ),
                      const SizedBox(height: 22),

                      BlocBuilder<ProductCubit, ProductState>(
                        builder: (context, state) {
                          return SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: state.isUploading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;

                                      final title = titleController.text.trim();
                                      final price = double.parse(
                                        priceController.text,
                                      );
                                      final desc = descController.text.trim();

                                      if (_pickedImage == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n?.translate(
                                                    'select_image_warning',
                                                  ) ??
                                                  'الرجاء اختيار صورة للمنتج',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      final success = await context
                                          .read<ProductCubit>()
                                          .uploadProduct(
                                            title: title,
                                            price: price,
                                            description: desc,
                                            category: selectedCategory,
                                            imagePath: _pickedImage!.path,
                                          );

                                      if (success && context.mounted) {
                                        Navigator.pop(ctx);

                                        context
                                            .read<NotificationCubit>()
                                            .notifyProductUploaded(title);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n?.translate(
                                                    'product_published',
                                                  ) ??
                                                  'تم نشر المنتج بنجاح! 🎉',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                        await _loadProducts();
                                      }
                                    },
                              child: state.isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.rocket_launch_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n?.translate('publish_product') ??
                                              'عرض المنتج للبيع 🚀',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white60 : Colors.black54,
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(height: 0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('my_products') ?? 'منتجاتي المعروضة',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.blueAccent : Colors.blueAccent,
            ),
            onPressed: () async {
              await _loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n?.translate('products_updated') ?? 'تم تحديث المنتجات',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 28,
              color: isDark ? Colors.blueAccent : Colors.blueAccent,
            ),
            onPressed: () => _showAddProductBottomSheet(context),
          ),
        ],
      ),
      body: BackgroundWidget(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          color: Colors.blueAccent,
          child: _isInitialLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                )
              : BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    final list = state.myProducts;

                    print('📊 MyProducts count in state: ${list.length}');

                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 90,
                                color: isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.12),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                l10n?.translate('no_products_for_sale') ??
                                    'لم تعرض أي منتجات للبيع بعد',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n?.translate('add_first_product') ??
                                    'أضف منتجك الأول الآن وابدأ البيع في سوق Vortex!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  l10n?.translate('add_first_product_now') ??
                                      'أضف أول منتج الآن',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                onPressed: () =>
                                    _showAddProductBottomSheet(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final product = list[index];
                        return _buildProductTile(product, l10n, isDark);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildProductTile(
    ProductModel product,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: _buildProductImage(product.image, isDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDark ? Colors.blueAccent : Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isApproved
                              ? Colors.green.withOpacity(0.15)
                              : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: product.isApproved
                                ? Colors.greenAccent.withOpacity(0.4)
                                : Colors.orangeAccent.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.isApproved
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.hourglass_top_rounded,
                              color: product.isApproved
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isApproved
                                  ? (l10n?.translate('for_sale') ??
                                        'معروض للبيع')
                                  : (l10n?.translate('pending_review') ??
                                        'قيد المراجعة'),
                              style: TextStyle(
                                color: product.isApproved
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imagePath, bool isDark) {
    final imageUrl = _getImageUrl(imagePath);

    if (imageUrl.isEmpty) {
      return _imagePlaceholder(isDark);
    }

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 90,
          height: 90,
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.blueAccent,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('🖼️ Image Load Error: $url -> $error');
          return _imagePlaceholder(isDark);
        },
      );
    }

    final file = File(imagePath.replaceFirst('file://', ''));
    if (file.existsSync()) {
      return Image.file(
        file,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
      );
    }

    return _imagePlaceholder(isDark);
  }

  Widget _imagePlaceholder([bool isDark = true]) {
    return Container(
      width: 90,
      height: 90,
      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white30 : Colors.black26,
        size: 35,
      ),
    );
  }
}
