import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('full_name') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _locationController.text = prefs.getString('location') ?? '';
      _bioController.text = prefs.getString('bio') ?? '';
    });
  }

  Future<void> _updateProfile() async {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.translate('enter_full_name') ?? 'الرجاء إدخال الاسم الكامل',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      try {
        final response = await ApiService().updateUserProfile(
          user_id: userId,
          full_name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          bio: _bioController.text.trim(),
        );

        if (response.statusCode == 200) {
          await prefs.setString('full_name', _nameController.text.trim());
          await prefs.setString('phone', _phoneController.text.trim());
          await prefs.setString('location', _locationController.text.trim());
          await prefs.setString('bio', _bioController.text.trim());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.translate('data_updated') ?? 'تم تحديث البيانات بنجاح',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _errorMessage =
                l10n?.translate('update_failed') ?? 'فشل تحديث البيانات';
          });
        }
      } catch (e) {
        await prefs.setString('full_name', _nameController.text.trim());
        await prefs.setString('phone', _phoneController.text.trim());
        await prefs.setString('location', _locationController.text.trim());
        await prefs.setString('bio', _bioController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n?.translate('saved_locally') ?? 'تم الحفظ محلياً'}: $e',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } else {
      setState(() {
        _errorMessage =
            l10n?.translate('user_not_logged_in') ?? 'المستخدم غير مسجل';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('edit_profile') ?? 'تعديل الملف الشخصي',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.grey.shade200,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildField(
                l10n?.translate('full_name') ?? 'الاسم الكامل *',
                _nameController,
                prefixIcon: Icons.person_outline,
                isDark: isDark,
              ),
              const SizedBox(height: 15),
              _buildField(
                l10n?.translate('phone') ?? 'رقم الهاتف',
                _phoneController,
                keyboard: TextInputType.phone,
                prefixIcon: Icons.phone_android_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 15),
              _buildField(
                l10n?.translate('location') ?? 'الموقع / العنوان',
                _locationController,
                prefixIcon: Icons.location_on_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 15),
              _buildField(
                l10n?.translate('bio') ?? 'نبذة شخصية',
                _bioController,
                maxLines: 3,
                prefixIcon: Icons.info_outline,
                isDark: isDark,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n?.translate('save') ?? 'حفظ التغييرات',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: isDark ? Colors.white54 : Colors.black54)
            : null,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }
}
