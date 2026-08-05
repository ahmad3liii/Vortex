import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/balance_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_bloc.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_event.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/presentation/screens/profilee/my_products_screen.dart';
import 'package:vortex_market/presentation/screens/profilee/messages_screen.dart';
import 'package:vortex_market/presentation/screens/profilee/reviews_screen.dart';
import 'package:vortex_market/presentation/screens/auth/login_screen.dart';
import 'package:vortex_market/presentation/screens/profilee/payment_methods_screen.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import '../widgets/background_widget.dart'; // ✅ استيراد الخلفية

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();

  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userLocation = "";
  String _userAvatar = "";
  String _userBio = "";
  int _userId = 0;
  bool _isLoading = true;
  String? _errorMessage;

  File? _selectedImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ✅ FIX: Load user data with proper error handling (Issue 4)
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');

      print('🆔 Loading profile for user: $userId');

      // ✅ إذا لم يكن userId موجوداً، حاول جلبها من AuthBloc
      if (userId == null) {
        final authState = context.read<AuthBloc>().state;
        if (authState.userData != null) {
          userId = authState.userData!['user_id'];
          if (userId != null) {
            await prefs.setInt('user_id', userId);
            print('✅ Retrieved user_id from AuthBloc: $userId');
          }
        }
      }

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'لم يتم العثور على معرف المستخدم، يرجى تسجيل الدخول مرة أخرى';
        });
        if (context.mounted) {
          context.read<AuthBloc>().add(LogoutEvent());
        }
        return;
      }

      _userId = userId;

      // تحميل البيانات المخزنة مؤقتاً (كاش)
      setState(() {
        _userName = prefs.getString('full_name') ?? "مستخدم";
        _userEmail = prefs.getString('email') ?? "";
        _userPhone = prefs.getString('phone') ?? "";
        _userLocation = prefs.getString('location') ?? "";
        _userAvatar = prefs.getString('avatar') ?? "";
        _userBio = prefs.getString('bio') ?? "";
      });

      // ✅ محاولة جلب أحدث البيانات من API مع إعادة المحاولة عند فشل 400
      bool apiSuccess = false;
      int retryCount = 0;
      const maxRetries = 2;

      while (!apiSuccess && retryCount < maxRetries) {
        try {
          final response = await _apiService.getUserProfile(userId!);
          print('📥 API Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = response.data;
            print('📥 User data: $data');

            setState(() {
              _userName = data['full_name'] ?? data['fullName'] ?? _userName;
              _userEmail = data['email'] ?? _userEmail;
              _userPhone = data['phone'] ?? data['mobile'] ?? _userPhone;
              _userLocation =
                  data['location'] ?? data['address'] ?? _userLocation;
              _userAvatar =
                  data['avatar'] ?? data['profile_image'] ?? _userAvatar;
              _userBio = data['bio'] ?? _userBio;
            });

            await prefs.setString('full_name', _userName);
            await prefs.setString('email', _userEmail);
            await prefs.setString('phone', _userPhone);
            await prefs.setString('location', _userLocation);
            await prefs.setString('avatar', _userAvatar);
            await prefs.setString('bio', _userBio);

            print('✅ Profile loaded: $_userName, $_userPhone, $_userLocation');
            apiSuccess = true;
            break;
          } else if (response.statusCode == 400) {
            print('⚠️ Received 400, retrying after reloading user_id');
            userId = prefs.getInt('user_id');
            if (userId == null) {
              final authState = context.read<AuthBloc>().state;
              if (authState.userData != null) {
                userId = authState.userData!['user_id'];
                if (userId != null) {
                  await prefs.setInt('user_id', userId);
                  print('✅ Reloaded user_id from AuthBloc: $userId');
                }
              }
            }
            if (userId != null) {
              _userId = userId;
              retryCount++;
              continue;
            } else {
              setState(() {
                _errorMessage =
                    'معرف المستخدم غير صالح، يرجى تسجيل الدخول مرة أخرى';
              });
              if (context.mounted) {
                context.read<AuthBloc>().add(LogoutEvent());
              }
              apiSuccess = true;
              break;
            }
          } else if (response.statusCode == 403 || response.statusCode == 401) {
            setState(() {
              _errorMessage = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى';
            });
            await _apiService.logout();
            if (context.mounted) {
              context.read<AuthBloc>().add(LogoutEvent());
            }
            apiSuccess = true;
            break;
          } else {
            setState(() {
              _errorMessage = 'فشل تحميل البيانات، يتم عرض البيانات المحفوظة';
            });
            apiSuccess = true;
            break;
          }
        } catch (e) {
          print('❌ API error attempt ${retryCount + 1}: $e');
          retryCount++;
          if (retryCount >= maxRetries) {
            setState(() {
              _errorMessage =
                  'تعذر الاتصال بالخادم بعد عدة محاولات، يتم عرض البيانات المحفوظة';
            });
            apiSuccess = true;
          }
        }
      }

      if (!apiSuccess) {
        setState(() {
          _errorMessage = 'تعذر تحميل البيانات، يتم عرض البيانات المحفوظة';
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع في تحميل البيانات';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.updateUserProfile(
        user_id: _userId,
        full_name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        bio: _userBio,
      );

      if (response.statusCode == 200) {
        setState(() {
          _userName = _nameController.text.trim();
          _userPhone = _phoneController.text.trim();
          _userLocation = _locationController.text.trim();
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('full_name', _userName);
        await prefs.setString('phone', _userPhone);
        await prefs.setString('location', _userLocation);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث البيانات بنجاح!")),
        );
        await _loadUserData();
      } else {
        setState(() {
          _errorMessage = 'فشل تحديث البيانات';
        });
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
    Navigator.pop(context);
  }

  void _showImagePickerOptions() {
    final appLocalizations = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appLocalizations?.changeAvatar ?? "تغيير الصورة الشخصية",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    label: appLocalizations?.camera ?? "الكاميرا",
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildImagePickerOption(
                    icon: Icons.photo_library,
                    label: appLocalizations?.gallery ?? "المعرض",
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final appLocalizations = AppLocalizations.of(context);
    _nameController.text = _userName;
    _emailController.text = _userEmail;
    _phoneController.text = _userPhone;
    _locationController.text = _userLocation;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          appLocalizations?.editProfile ?? "تعديل الملف الشخصي",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField(
                controller: _nameController,
                hint: appLocalizations?.fullName ?? "الاسم الكامل",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
              _buildEditTextField(
                controller: _emailController,
                hint: appLocalizations?.email ?? "البريد الإلكتروني",
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 15),
              _buildEditTextField(
                controller: _phoneController,
                hint: appLocalizations?.phone ?? "رقم الهاتف",
                icon: Icons.phone_android_outlined,
              ),
              const SizedBox(height: 15),
              _buildEditTextField(
                controller: _locationController,
                hint: appLocalizations?.location ?? "الموقع",
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              appLocalizations?.cancel ?? "إلغاء",
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(context);
              _updateUserProfile();
            },
            child: Text(appLocalizations?.save ?? "حفظ"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _getImageUrl(String? url) {
    return ApiService.getFullImageUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';
    final isDark = context.watch<ThemeCubit>().isDark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_errorMessage != null && _errorMessage!.contains('تسجيل الدخول')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutEvent());
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('تسجيل الدخول مرة أخرى'),
            ),
          ],
        ),
      );
    }

    return BackgroundWidget(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 120),
            _buildProfileHeader(appLocalizations),
            const SizedBox(height: 20),

            _buildProfileMenu(
              icon: Icons.inventory_2_rounded,
              title: appLocalizations?.myProducts ?? "منتجاتي المعروضة",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProductsScreen(),
                  ),
                );
              },
            ),

            _buildProfileMenu(
              icon: Icons.message_rounded,
              title: appLocalizations?.messages ?? "الرسائل",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MessagesScreen(),
                  ),
                );
              },
            ),

            _buildProfileMenu(
              icon: Icons.star_rounded,
              title: appLocalizations?.reviews ?? "تقييماتي",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewsScreen(),
                  ),
                );
              },
            ),

            _buildLanguageSwitch(appLocalizations, isEnglish),

            // ✅ إضافة زر تبديل الوضع (الليلي/النهاري)
            _buildThemeSwitch(appLocalizations, isDark),

            const Divider(color: Colors.white10, height: 40),

            _buildProfileMenu(
              icon: Icons.logout_rounded,
              title: appLocalizations?.logout ?? "تسجيل الخروج",
              color: Colors.redAccent,
              onTap: () => _showLogoutDialog(context, appLocalizations),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations? appLocalizations) {
    final isDark = context.watch<ThemeCubit>().isDark;

    return GestureDetector(
      onTap: _showEditProfileDialog,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          )
                        : _userAvatar.isNotEmpty
                        ? Image.network(
                            _getImageUrl(_userAvatar),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white54,
                                ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white54,
                          ),
                  ),
                ),
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodsScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF3A4256), Color(0xFF1E2433)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFD4C5F9), Color(0xFFB8A9D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: BlocBuilder<BalanceCubit, BalanceState>(
                  builder: (context, state) {
                    final cardCount = state.cards.length;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card_rounded,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "بطاقات الدفع والفيزا",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cardCount > 0
                                      ? "لديك $cardCount بطاقات محفوظة"
                                      : "اضغط لإضافة بطاقة دفع",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 16,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            Text(
              _userName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _userLocation.isNotEmpty ? _userLocation : "لم يتم تحديد",
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (_userBio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _userBio,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                appLocalizations?.editProfile ?? "اضغط لتعديل البيانات",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 10),
              ),
            ),
            if (_errorMessage != null && !_errorMessage!.contains('تسجيل'))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    final isDark = context.watch<ThemeCubit>().isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Row(
            children: [
              Icon(icon, color: color.withOpacity(0.8), size: 24),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? color : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? color.withOpacity(0.3) : Colors.black26,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitch(
    AppLocalizations? appLocalizations,
    bool isEnglish,
  ) {
    final isDark = context.watch<ThemeCubit>().isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            const Icon(Icons.language_rounded, color: Colors.white70, size: 24),
            const SizedBox(width: 15),
            Text(
              appLocalizations?.language ?? "اللغة",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEnglish ? "EN" : "AR",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isEnglish,
                    onChanged: (value) {
                      context.read<LanguageCubit>().toggleLanguage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            appLocalizations?.languageChanged ??
                                "تم تغيير اللغة",
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    activeColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ إضافة زر تبديل الوضع (الليلي/النهاري)
  Widget _buildThemeSwitch(AppLocalizations? appLocalizations, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              color: isDark ? Colors.amberAccent : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 15),
            Text(
              appLocalizations?.translate('theme_mode') ?? "الوضع",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Switch(
              value: isDark,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
              activeColor: Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AppLocalizations? appLocalizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B2F),
        title: Text(
          appLocalizations?.logout ?? "تسجيل الخروج",
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          appLocalizations?.logoutConfirm ??
              "هل أنت متأكد أنك تريد الخروج من Vortex؟",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              appLocalizations?.no ?? "إلغاء",
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _apiService.logout();
              if (context.mounted) {
                context.read<AuthBloc>().add(LogoutEvent());
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(appLocalizations?.yes ?? "خروج"),
          ),
        ],
      ),
    );
  }
}
