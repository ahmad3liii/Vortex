import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart'; // ✅ استيراد الخلفية الديناميكية

class ProductFilterScreen extends StatefulWidget {
  const ProductFilterScreen({super.key});

  @override
  State<ProductFilterScreen> createState() => _ProductFilterScreenState();
}

class _ProductFilterScreenState extends State<ProductFilterScreen> {
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;
  String? _selectedCategory;
  String? _selectedSort;

  final List<String> categoriesAr = [
    "الكل",
    "ملابس",
    "إكسسوارات",
    "أجهزة ذكية",
    "أثاث",
    "مواد غذائية",
  ];

  final List<String> categoriesEn = [
    "All",
    "Clothing",
    "Accessories",
    "Smart Devices",
    "Furniture",
    "Groceries",
  ];

  final List<String> sortOptionsAr = [
    "الأحدث",
    "السعر: الأقل أولاً",
    "السعر: الأعلى أولاً",
    "التقييم",
  ];

  final List<String> sortOptionsEn = [
    "Newest",
    "Price: Low to High",
    "Price: High to Low",
    "Rating",
  ];

  final List<String> sortValuesEn = [
    "newest",
    "price_asc",
    "price_desc",
    "rating",
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<ProductCubit>().state;
    _minPrice = state.minPrice ?? 0;
    _maxPrice = state.maxPrice ?? 1000;
    _minRating = state.minRating ?? 0;
    _selectedCategory = state.selectedCategory;
    _selectedSort = state.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';
    final isDark = context.watch<ThemeCubit>().isDark;
    final categories = isEnglish ? categoriesEn : categoriesAr;
    final sortOptions = isEnglish ? sortOptionsEn : sortOptionsAr;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.grey.shade200,
        elevation: 0,
        title: Text(
          isEnglish ? 'Filters' : 'الفلاتر',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Filter
              _buildFilterSection(
                title: isEnglish ? 'Category' : 'الفئة',
                isDark: isDark,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var category in categories)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.sp),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected
                                    ? category
                                    : categories.first;
                              });
                            },
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            selectedColor: const Color(0xFFA855F7),
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.sp),

              // Price Range Filter
              _buildFilterSection(
                title: isEnglish ? 'Price Range' : 'نطاق السعر',
                isDark: isDark,
                child: Column(
                  children: [
                    Text(
                      '${_minPrice.toStringAsFixed(0)} - ${_maxPrice.toStringAsFixed(0)} USD',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 10.sp),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0,
                      max: 1000,
                      divisions: 100,
                      onChanged: (RangeValues values) {
                        setState(() {
                          _minPrice = values.start;
                          _maxPrice = values.end;
                        });
                      },
                      activeColor: const Color(0xFFA855F7),
                      inactiveColor: isDark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.sp),

              // Rating Filter
              _buildFilterSection(
                title: isEnglish ? 'Minimum Rating' : 'الحد الأدنى للتقييم',
                isDark: isDark,
                child: Column(
                  children: [
                    Text(
                      '⭐ ${_minRating.toStringAsFixed(1)}+',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.sp),
                    Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          _minRating = value;
                        });
                      },
                      activeColor: const Color(0xFFA855F7),
                      inactiveColor: isDark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.sp),

              // Sort Option
              _buildFilterSection(
                title: isEnglish ? 'Sort By' : 'الترتيب حسب',
                isDark: isDark,
                child: DropdownButton<String>(
                  value: _selectedSort,
                  isExpanded: true,
                  dropdownColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade200,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12.sp,
                  ),
                  items: [
                    for (int i = 0; i < sortOptions.length; i++)
                      DropdownMenuItem(
                        value: sortValuesEn[i],
                        child: Text(sortOptions[i]),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSort = value;
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 30.sp),

              // Apply & Clear Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ProductCubit>().clearFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.grey[700]
                            : Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 12.sp),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                        ),
                      ),
                      child: Text(
                        isEnglish ? 'Clear' : 'مسح',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.sp),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B39A0), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(10.sp),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.read<ProductCubit>().applyFilters(
                            category: _selectedCategory,
                            minPrice: _minPrice,
                            maxPrice: _maxPrice,
                            minRating: _minRating,
                          );
                          if (_selectedSort != null) {
                            context.read<ProductCubit>().sortProducts(
                              _selectedSort!,
                            );
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 12.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                        ),
                        child: Text(
                          isEnglish ? 'Apply' : 'تطبيق',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.sp),
        Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10.sp),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
