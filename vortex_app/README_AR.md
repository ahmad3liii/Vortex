الملف الذي أرسلته هو ملف **README.md** الخاص بمشروع **Vortex Market**، وهو ملف تعريف عام للمشروع. بعد تعديله، سيصبح مناسباً لعرضه على صفحة الـ GitHub الرئيسية ويعكس التغييرات الأخيرة التي أضفناها (الوضع الليلي، شاشة التحميل، الترجمة، تحسينات الواجهة، إلخ).

لقد قمت بتعديله ليكون **أكثر احترافية ووضوحاً**، مع إضافة أقسام جديدة تشرح **الميزات الجديدة** و **طريقة التثبيت** و **البنية** و **الأوامر** وغيرها.

---

# 📄 **الملف المعدل - README.md**

```markdown
# 🛒 Vortex Market - Flutter App

> **منصة تجارة إلكترونية متكاملة**  
> تطبيق موبايل حديث مع نظام فلاتر متقدم، رفع منتجات، دفع عبر Stripe، ودعم كامل للغتين العربية والإنجليزية.

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-green?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)]()
[![Dark Mode](https://img.shields.io/badge/Dark%20Mode-Supported-purple)]()
[![Localization](https://img.shields.io/badge/Localization-AR%20%7C%20EN-orange)]()

---

## ✨ **الميزات الرئيسية**

### 🔍 **نظام الفلاتر المتقدم**
- فلترة حسب **الفئة** (6 فئات: ملابس، إلكترونيات، أثاث، إلخ)
- فلترة **نطاق السعر** باستخدام Range Slider
- فلترة حسب **التقييم** (0-5 نجوم)
- خيارات **ترتيب** متقدمة (الأحدث، السعر تصاعدياً/تنازلياً، التقييم)

### 📤 **رفع المنتجات**
- رفع **صور متعددة** للمنتج
- **معاينة** الصور قبل الرفع
- إدخال البيانات الكاملة (العنوان، السعر، الفئة، الوصف)
- معالجة شاملة للأخطاء والتحقق من البيانات

### 💳 **نظام الدفع (Stripe)**
- إدخال بيانات البطاقة **بشكل آمن**
- معالجة الدفع عبر **Stripe**
- تأكيد وتتبع المدفوعات
- رسائل نجاح/فشل واضحة للمستخدم

### 🌐 **دعم متقدم**
- دعم كامل للغتين **العربية والإنجليزية** (RTL / LTR)
- **تصميم متجاوب** مع جميع أحجام الشاشات (باستخدام Sizer)
- **Animations** و **Transitions** سلسة
- معالجة شاملة للأخطاء مع رسائل توضيحية

### 🌗 **الوضع الليلي والنهاري**
- زر تبديل الوضع في صفحة الملف الشخصي
- خلفية ديناميكية متوافقة مع الوضعين
- ألوان مريحة للعين في الإضاءة المنخفضة

### 🔐 **أمان متقدم**
- مصادقة باستخدام **JWT** (Access Token + Refresh Token)
- تخزين آمن للتوكنات في SharedPreferences
- حماية كلمات المرور (تشفير PBKDF2)
- إشعارات أمنية عند تسجيل الدخول من أجهزة جديدة

### 💬 **دردشة فورية**
- محادثات مباشرة بين البائع والمشتري
- إرسال واستقبال الرسائل في الوقت الفعلي (Polling)
- عرض رسائل المستخدم (`is_me`) بشكل مميز

### 🔔 **إشعارات لحظية**
- إشعارات عند تغيير حالة الطلب
- إشعارات عند وصول رسائل جديدة
- إشعارات عند الموافقة على المنتجات

---

## 📁 **هيكل المشروع**

```
lib/
├── main.dart                      # نقطة انطلاق التطبيق
├── data/
│   ├── models/                    # نماذج البيانات
│   │   └── app_models.dart        # جميع النماذج (User, Product, Order, Chat...)
│   └── repositories/              # مستودعات البيانات
│       ├── product_repo.dart      # إدارة المنتجات
│       └── payment_repo.dart      # إدارة المدفوعات
├── logic/
│   ├── cubits/                    # حاويات الحالة
│   │   ├── product_cubit.dart     # إدارة المنتجات (جلب، فلترة، رفع)
│   │   ├── payment_cubit.dart     # إدارة الدفع
│   │   ├── chat_cubit.dart        # إدارة الدردشة
│   │   ├── theme_cubit.dart       # إدارة الوضع الليلي/النهاري (NEW)
│   │   └── ...
│   ├── login_bloc/                # نظام المصادقة
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   └── services/
│       └── api_service.dart       # خدمة API (40+ endpoint)
├── l10n/                          # الترجمة والتدويل
│   └── app_localizations.dart     # دعم العربية والإنجليزية
└── presentation/
    ├── screens/                   # شاشات التطبيق
    │   ├── auth/                  # تسجيل الدخول والتسجيل
    │   ├── home/                  # الشاشة الرئيسية
    │   ├── chat/                  # الدردشة
    │   ├── profile/               # الملف الشخصي
    │   ├── product/               # المنتجات والفلترة
    │   ├── checkout/              # الدفع
    │   └── main_navigation_screen.dart  # شريط التنقل
    └── widgets/                   # مكونات قابلة لإعادة الاستخدام
        ├── background_widget.dart # خلفية ديناميكية (NEW)
        └── product_card.dart      # بطاقة المنتج
```

---

## 🚀 **الإعداد السريع**

### 1. **متطلبات النظام**
- Flutter 3.0+
- Dart 3.0+
- Android SDK 21+ (للتشغيل على Android)
- iOS 10.0+ (للتشغيل على iOS)

### 2. **التثبيت**
```bash
# 1. انتقل إلى مجلد المشروع
cd vortex_app

# 2. تحميل الاعتماديات
flutter pub get

# 3. (اختياري) تنظيف المشروع
flutter clean
```

### 3. **التكوين**
```dart
// في ملف lib/logic/services/api_service.dart
// غيّر عنوان الـ API إلى عنوان الخادم الخاص بك
static const String baseUrl = 'http://YOUR_SERVER_IP:8000/api/';
```

### 4. **التشغيل**
```bash
# تشغيل على جهاز متصل أو محاكي
flutter run

# تشغيل مع إعادة بناء تلقائية (Hot Reload)
flutter run --no-cache

# بناء APK للإنتاج
flutter build apk --release

# بناء App Bundle للإنتاج
flutter build appbundle --release
```

---

## 💻 **الأوامر المهمة**

| الأمر | الوصف |
|-------|-------|
| `flutter pub get` | تحميل جميع الاعتماديات |
| `flutter clean` | تنظيف الملفات المؤقتة |
| `flutter run` | تشغيل التطبيق |
| `flutter build apk --release` | بناء APK للإنتاج |
| `flutter build appbundle --release` | بناء App Bundle |
| `flutter build ios --release` | بناء iOS IPA |
| `flutter test` | تشغيل الاختبارات |

---

## 🎨 **نظام الألوان**

### **الوضع الليلي (Dark Mode)**
```dart
Background: #0F0F1F (أسود عميق)
Surface:     #1A1A2E (أسود أفتح)
Primary:     #5B39A0 (بنفسجي داكن)
Accent:      #A855F7 (بنفسجي فاتح)
```

### **الوضع النهاري (Light Mode)**
```dart
Background: #F5F0FF (أبيض بنفسجي فاتح)
Surface:     #E8E0F0 (رمادي بنفسجي)
Primary:     #5B39A0 (بنفسجي داكن)
Accent:      #A855F7 (بنفسجي فاتح)
```

---

## 📊 **الإحصائيات**

| المقياس | القيمة |
|--------|--------|
| **ملفات جديدة** | 5+ ملفات |
| **ملفات محدثة** | 20+ ملف |
| **أسطر مضافة** | ~1,500 سطر |
| **دوال جديدة** | 40+ دالة |
| **API Endpoints** | 40+ endpoint |
| **شاشات** | 16 شاشة |
| **لغات مدعومة** | 2 (عربية + إنجليزية) |

---

## 🔐 **الأمان**

| الآلية | الحالة |
|--------|--------|
| JWT Authentication | ✅ مفعّل |
| تشفير كلمات المرور (PBKDF2) | ✅ مفعّل |
| Refresh Token | ✅ مفعّل |
| تخزين آمن للتوكنات | ✅ مفعّل |
| إشعارات أمنية | ✅ مفعّل |
| Input Validation | ✅ مفعّل |
| SQL Injection Prevention | ✅ مفعّل |
| CORS Policy | ✅ مفعّل |
| HTTPS/TLS | ✅ في الإنتاج |

---

## 🧪 **قائمة الاختبار**

- [ ] تسجيل الدخول وإنشاء حساب جديد
- [ ] تصفح المنتجات مع الفلاتر
- [ ] البحث عن منتجات محددة
- [ ] رفع منتج جديد مع صورة
- [ ] شراء منتج عبر Stripe
- [ ] الدردشة مع البائع
- [ ] تحديث حالة الطلب (للبائع)
- [ ] إدارة الملف الشخصي
- [ ] تبديل اللغة (عربي/إنجليزي)
- [ ] تبديل الوضع (ليلي/نهاري)
- [ ] عرض الإشعارات

---

## 📚 **التوثيق الإضافي**

1. **[USER_GUIDE.md](USER_GUIDE.md)** - دليل الاستخدام الكامل
2. **[API_DOCS.md](API_DOCS.md)** - توثيق واجهات API
3. **[CHANGES_LOG.md](CHANGES_LOG.md)** - سجل التغييرات الكامل
4. **[DEPLOYMENT.md](DEPLOYMENT.md)** - دليل النشر على الخوادم

---

## 🤝 **المساهمة**

نرحب بالمساهمات! يرجى اتباع الخطوات التالية:

1. **Fork** المشروع
2. إنشاء **فرع** للميزة الجديدة (`git checkout -b feature/AmazingFeature`)
3. **Commit** التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. **Push** إلى الفرع (`git push origin feature/AmazingFeature`)
5. فتح **Pull Request**

---

## 📞 **الدعم**

للمساعدة أو الاستفسارات:
- اقرأ [USER_GUIDE.md](USER_GUIDE.md)
- تحقق من [CHANGES_LOG.md](CHANGES_LOG.md)
- افتح **Issue** على GitHub
- تواصل مع فريق التطوير

---

## 👨‍💻 **فريق التطوير**

| الاسم | الدور |
|-------|-------|
| أحمد زيان علي | مطور Flutter (Full Stack) |
| مضر علي عبدهللا |مطور Web (React) |
| جوى جعفر عبد الهادي | مطور Backend (Django) |

**المشرف:** د. باسل حبيب حسن

---

## ✅ **جاهز للإنتاج**

<div align="center">

**⭐ قم بوضع نجمة للمشروع على GitHub**

**[Vortex Market - Flutter App]**  
**Status:** ✅ **Production Ready**  
**Version:** 1.0.0

</div>

---

**📌 ملاحظة:** هذا التطبيق جزء من مشروع تخرج في **هندسة البرمجيات ونظم المعلومات**. جميع الحقوق محفوظة © 2026

```