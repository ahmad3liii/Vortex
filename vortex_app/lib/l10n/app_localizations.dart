import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    String jsonString = await _loadLanguageFile(locale.languageCode);
    _localizedStrings = _parseJson(jsonString);
    return true;
  }

  Future<String> _loadLanguageFile(String languageCode) async {
    if (languageCode == 'ar') {
      return '''
{
  "app_name": "فووتركس ماركت",
  "home": "الرئيسية",
  "search": "البحث",
  "profile": "حسابي",
  "my_products": "منتجاتي المعروضة",
  "messages": "الرسائل",
  "reviews": "تقييماتي",
  "language": "اللغة",
  "logout": "تسجيل الخروج",
  "edit_profile": "تعديل الملف الشخصي",
  "save": "حفظ",
  "cancel": "إلغاء",
  "full_name": "الاسم الكامل",
  "email": "البريد الإلكتروني",
  "phone": "رقم الهاتف",
  "location": "الموقع",
  "change_avatar": "تغيير الصورة الشخصية",
  "camera": "الكاميرا",
  "gallery": "المعرض",
  "logout_confirm": "هل أنت متأكد أنك تريد الخروج؟",
  "yes": "نعم",
  "no": "لا",
  "data_updated": "تم تحديث البيانات بنجاح!",
  "language_changed": "تم تغيير اللغة",
  "seller": "البائع",
  "buyer": "المشتري",
  "description": "الوصف",
  "direct_chat": "تواصل مباشر",
  "confirm_purchase": "تأكيد الشراء",
  "purchase_confirm_message": "هل تود إرسال طلب شراء رسمي لهذا المنتج؟ سيتم إشعار البائع فوراً.",
  "send_request": "إرسال الطلب",
  "request_sent": "تم إرسال طلبك بنجاح!",
  "balance": "الرصيد",
  "add_balance": "شحن الرصيد",
  "current_balance": "الرصيد الحالي",
  "select_amount": "اختر المبلغ",
  "enter_amount": "أدخل المبلغ",
  "product_price": "سعر المنتج",
  "your_balance": "رصيدك",
  "insufficient_balance": "رصيد غير كافٍ، يرجى شحن الرصيد أولاً",
  "purchase_success": "تم الشراء بنجاح!",
  "purchase_failed": "فشلت عملية الشراء",
  "purchases": "مشترياتي",

  // 🔹 مفاتيح جديدة لشاشة الطلبات
  "my_orders": "الطلبات",
  "my_purchases": "🛍️  مشترياتي",
  "sales_orders": "📦  طلبات البيع",
  "no_purchases": "لم تقم بشراء أي منتجات بعد",
  "browse_market": "تصفّح السوق واشترِ أول منتج بالفيزا كارد!",
  "no_sales": "لا توجد طلبات بيع واردة بعد",
  "when_sold": "عندما يشتري أحد منتجاتك سيظهر الطلب هنا.",
  "pending": "قيد الانتظار",
  "processing": "قيد التجهيز",
  "shipped": "تم الشحن",
  "delivered": "تم التسليم ✓",
  "cancelled": "ملغي",
  "start_processing": "بدء التجهيز",
  "confirm_delivery": "تأكيد التسليم",

  // 🔹 مفاتيح جديدة لشاشة منتجاتي المعروضة
  "add_product": "أضف منتجاً",
  "for_sale": "معروض للبيع",
  "pending_review": "قيد المراجعة",
  "add_product_title": "إضافة منتج جديد للبيع",
  "tap_to_add_image": "اضغط لإضافة صورة المنتج",
  "from_camera_or_gallery": "من الكاميرا أو المعرض",
  "product_name": "اسم المنتج",
  "price_usd": "السعر بالدولار",
  "category": "الفئة",
  "product_description": "وصف المنتج بالتفصيل",
  "required_field": "الحقل مطلوب",
  "enter_valid_number": "أدخل رقم صحيح",
  "select_image_warning": "الرجاء اختيار صورة للمنتج",
  "product_published": "تم نشر المنتج بنجاح! 🎉",
  "publish_product": "عرض المنتج للبيع 🚀",
  "no_products_for_sale": "لم تعرض أي منتجات للبيع بعد",
  "add_first_product": "أضف منتجك الأول الآن وابدأ البيع في سوق Vortex!",
  "add_first_product_now": "أضف أول منتج الآن",
  "products_updated": "تم تحديث المنتجات"
}
''';
    } else {
      return '''
{
  "app_name": "Vortex Market",
  "home": "Home",
  "search": "Search",
  "profile": "Profile",
  "my_products": "My Products",
  "messages": "Messages",
  "reviews": "Reviews",
  "language": "Language",
  "logout": "Logout",
  "edit_profile": "Edit Profile",
  "save": "Save",
  "cancel": "Cancel",
  "full_name": "Full Name",
  "email": "Email",
  "phone": "Phone Number",
  "location": "Location",
  "change_avatar": "Change Avatar",
  "camera": "Camera",
  "gallery": "Gallery",
  "logout_confirm": "Are you sure you want to logout?",
  "yes": "Yes",
  "no": "No",
  "data_updated": "Profile updated successfully!",
  "language_changed": "Language changed",
  "seller": "Seller",
  "buyer": "Buyer",
  "description": "Description",
  "direct_chat": "Direct Chat",
  "confirm_purchase": "Confirm Purchase",
  "purchase_confirm_message": "Would you like to send a purchase request for this product? The seller will be notified immediately.",
  "send_request": "Send Request",
  "request_sent": "Your request has been sent successfully!",
  "balance": "Balance",
  "add_balance": "Add Balance",
  "current_balance": "Current Balance",
  "select_amount": "Select Amount",
  "enter_amount": "Enter Amount",
  "product_price": "Product Price",
  "your_balance": "Your Balance",
  "insufficient_balance": "Insufficient balance, please add balance first",
  "purchase_success": "Purchase successful!",
  "purchase_failed": "Purchase failed",
  "purchases": "Purchases",

  // 🔹 New keys for orders screen
  "my_orders": "Orders",
  "my_purchases": "🛍️  My Purchases",
  "sales_orders": "📦  Sales Orders",
  "no_purchases": "You haven't purchased any products yet",
  "browse_market": "Browse the market and buy your first product with Visa!",
  "no_sales": "No incoming sales orders yet",
  "when_sold": "When someone buys your product, it will appear here.",
  "pending": "Pending",
  "processing": "Processing",
  "shipped": "Shipped",
  "delivered": "Delivered ✓",
  "cancelled": "Cancelled",
  "start_processing": "Start Processing",
  "confirm_delivery": "Confirm Delivery",

  // 🔹 New keys for my products screen
  "add_product": "Add Product",
  "for_sale": "For Sale",
  "pending_review": "Pending Review",
  "add_product_title": "Add New Product for Sale",
  "tap_to_add_image": "Tap to add product image",
  "from_camera_or_gallery": "From camera or gallery",
  "product_name": "Product Name",
  "price_usd": "Price (USD)",
  "category": "Category",
  "product_description": "Product Description",
  "required_field": "This field is required",
  "enter_valid_number": "Enter a valid number",
  "select_image_warning": "Please select a product image",
  "product_published": "Product published successfully! 🎉",
  "publish_product": "Publish Product 🚀",
  "no_products_for_sale": "You haven't listed any products for sale yet",
  "add_first_product": "Add your first product now and start selling on Vortex Market!",
  "add_first_product_now": "Add First Product Now",
  "products_updated": "Products updated"
}
''';
    }
  }

  Map<String, String> _parseJson(String jsonString) {
    Map<String, String> result = {};
    RegExp regExp = RegExp(r'"([^"]+)":\s*"([^"]+)"');
    Iterable<Match> matches = regExp.allMatches(jsonString);
    for (Match match in matches) {
      if (match.groupCount == 2) {
        result[match.group(1)!] = match.group(2)!;
      }
    }
    return result;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Getters (للتوافق مع الكود القديم)
  String get appName => translate('app_name');
  String get home => translate('home');
  String get search => translate('search');
  String get profile => translate('profile');
  String get myProducts => translate('my_products');
  String get messages => translate('messages');
  String get reviews => translate('reviews');
  String get language => translate('language');
  String get logout => translate('logout');
  String get editProfile => translate('edit_profile');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get fullName => translate('full_name');
  String get email => translate('email');
  String get phone => translate('phone');
  String get location => translate('location');
  String get changeAvatar => translate('change_avatar');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get logoutConfirm => translate('logout_confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get dataUpdated => translate('data_updated');
  String get languageChanged => translate('language_changed');
  String get balance => translate('balance');
  String get addBalance => translate('add_balance');
  String get currentBalance => translate('current_balance');
  String get selectAmount => translate('select_amount');
  String get enterAmount => translate('enter_amount');
  String get productPrice => translate('product_price');
  String get yourBalance => translate('your_balance');
  String get insufficientBalance => translate('insufficient_balance');
  String get purchaseSuccess => translate('purchase_success');
  String get purchaseFailed => translate('purchase_failed');
  String get seller => translate('seller');
  String get buyer => translate('buyer');
  String get description => translate('description');
  String get directChat => translate('direct_chat');
  String get confirmPurchase => translate('confirm_purchase');
  String get purchaseConfirmMessage => translate('purchase_confirm_message');
  String get sendRequest => translate('send_request');
  String get requestSent => translate('request_sent');
  String get purchases => translate('purchases');
  String get myOrders => translate('my_orders');
  String get myPurchases => translate('my_purchases');
  String get salesOrders => translate('sales_orders');
  String get noPurchases => translate('no_purchases');
  String get browseMarket => translate('browse_market');
  String get noSales => translate('no_sales');
  String get whenSold => translate('when_sold');
  String get pending => translate('pending');
  String get processing => translate('processing');
  String get shipped => translate('shipped');
  String get delivered => translate('delivered');
  String get cancelled => translate('cancelled');
  String get startProcessing => translate('start_processing');
  String get confirmDelivery => translate('confirm_delivery');
  String get addProduct => translate('add_product');
  String get forSale => translate('for_sale');
  String get pendingReview => translate('pending_review');
  String get addProductTitle => translate('add_product_title');
  String get tapToAddImage => translate('tap_to_add_image');
  String get fromCameraOrGallery => translate('from_camera_or_gallery');
  String get productName => translate('product_name');
  String get priceUsd => translate('price_usd');
  String get category => translate('category');
  String get productDescription => translate('product_description');
  String get requiredField => translate('required_field');
  String get enterValidNumber => translate('enter_valid_number');
  String get selectImageWarning => translate('select_image_warning');
  String get productPublished => translate('product_published');
  String get publishProduct => translate('publish_product');
  String get noProductsForSale => translate('no_products_for_sale');
  String get addFirstProduct => translate('add_first_product');
  String get addFirstProductNow => translate('add_first_product_now');
  String get productsUpdated => translate('products_updated');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
