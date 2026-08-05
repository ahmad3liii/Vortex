import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import '../widgets/background_widget.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedCategory;
  File? _selectedImage;

  final List<String> categoriesAr = [
    "ملابس",
    "إكسسوارات",
    "أجهزة ذكية",
    "أثاث",
    "مواد غذائية",
  ];

  final List<String> categoriesEn = [
    "Clothing",
    "Accessories",
    "Smart Devices",
    "Furniture",
    "Groceries",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        Fluttertoast.showToast(
          msg: 'تم اختيار الصورة بنجاح',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'خطأ في اختيار الصورة',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _submitProduct() {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';

    if (_titleController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: isEnglish
            ? 'Please enter product title'
            : 'الرجاء إدخال اسم المنتج',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Please enter price' : 'الرجاء إدخال السعر',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Please enter valid price' : 'الرجاء إدخال سعر صحيح',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_selectedCategory == null) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Please select category' : 'الرجاء اختيار فئة',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_selectedImage == null) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Please select an image' : 'الرجاء اختيار صورة',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Please enter description' : 'الرجاء إدخال الوصف',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    final String imagePath = _selectedImage!.path;
    if (imagePath.isEmpty) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Invalid image path' : 'مسار الصورة غير صالح',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
      return;
    }

    print('📤 Uploading product with image: $imagePath');

    context.read<ProductCubit>().uploadProduct(
      title: _titleController.text,
      price: price,
      description: _descriptionController.text,
      category: _selectedCategory!,
      imagePath: imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';
    final isDark = context.watch<ThemeCubit>().isDark;
    final categories = isEnglish ? categoriesEn : categoriesAr;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.grey.shade200,
        title: Text(
          isEnglish ? 'Upload Product' : 'رفع منتج',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state.isUploadSuccess) {
            Fluttertoast.showToast(
              msg: isEnglish
                  ? 'Product uploaded successfully!'
                  : 'تم رفع المنتج بنجاح!',
              toastLength: Toast.LENGTH_SHORT,
              backgroundColor: Colors.green,
            );
            _titleController.clear();
            _priceController.clear();
            _descriptionController.clear();
            setState(() {
              _selectedImage = null;
              _selectedCategory = null;
            });
            context.read<ProductCubit>().resetUploadStatus();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.pop(context, true);
              }
            });
          }
          if (state.errorMessage != null && !state.isUploading) {
            Fluttertoast.showToast(
              msg: state.errorMessage!,
              toastLength: Toast.LENGTH_LONG,
              backgroundColor: Colors.red,
            );
          }
        },
        child: BackgroundWidget(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: isEnglish ? 'Product Title' : 'اسم المنتج',
                  controller: _titleController,
                  isEnglish: isEnglish,
                  isDark: isDark,
                ),
                SizedBox(height: 16.sp),

                _buildTextField(
                  label: isEnglish ? 'Price (USD)' : 'السعر (USD)',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  isEnglish: isEnglish,
                  isDark: isDark,
                ),
                SizedBox(height: 16.sp),

                Text(
                  isEnglish ? 'Category' : 'الفئة',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.sp),
                DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade200,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12.sp,
                  ),
                  hint: Text(
                    isEnglish ? 'Select Category' : 'اختر الفئة',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  items: [
                    for (var category in categories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                SizedBox(height: 16.sp),

                Text(
                  isEnglish ? 'Product Image' : 'صورة المنتج',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.sp),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200.sp,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10.sp),
                      border: Border.all(
                        color: _selectedImage != null
                            ? Colors.green
                            : (isDark ? Colors.white24 : Colors.black26),
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10.sp),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8.sp,
                                right: 8.sp,
                                child: GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    padding: EdgeInsets.all(4.sp),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40.sp,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              SizedBox(height: 8.sp),
                              Text(
                                isEnglish
                                    ? 'Tap to select image'
                                    : 'اضغط لاختيار صورة',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 16.sp),

                Text(
                  isEnglish ? 'Description' : 'الوصف',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.sp),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: isEnglish
                        ? 'Enter product description...'
                        : 'أدخل وصف المنتج...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.sp),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.sp),
                      borderSide: const BorderSide(
                        color: Color(0xFFA855F7),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.sp),

                BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B39A0), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(10.sp),
                      ),
                      child: ElevatedButton(
                        onPressed: state.isUploading ? null : _submitProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 14.sp),
                          minimumSize: Size(double.infinity, 50.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                        ),
                        child: state.isUploading
                            ? SizedBox(
                                height: 20.sp,
                                width: 20.sp,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEnglish ? 'Upload Product' : 'رفع المنتج',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required bool isEnglish,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.sp),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.sp),
              borderSide: const BorderSide(
                color: Color(0xFFA855F7),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
