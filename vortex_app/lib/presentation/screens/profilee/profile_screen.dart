import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/presentation/screens/profilee/edit_profile_screen.dart';
import 'package:vortex_market/presentation/screens/profilee/my_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  
  String userName = "تحميل...";
  String userEmail = "...";
  String userPhone = "...";
  String userLocation = "...";
  String userBio = "";
  String userAvatar = "";
  int? userId;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id');

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يجب تسجيل الدخول أولاً';
        });
        return;
      }

      // Try to fetch from API first
      try {
        final response = await _apiService.getUserProfile(userId!);
        if (response.statusCode == 200) {
          final data = response.data;
          userName = data['full_name'] ?? data['fullName'] ?? "مستخدم Vortex";
          userEmail = data['email'] ?? "لا يوجد بريد مسجل";
          userPhone = data['phone'] ?? "لا يوجد هاتف مسجل";
          userLocation = data['location'] ?? "الموقع غير محدد";
          userBio = data['bio'] ?? "";
          
          // Handle avatar URL
          final avatarPath = data['profile_image'] ?? data['avatar'] ?? '';
          userAvatar = ApiService.getFullImageUrl(avatarPath);
          
          // Save to SharedPreferences for offline access
          await prefs.setString('full_name', userName);
          await prefs.setString('email', userEmail);
          await prefs.setString('phone', userPhone);
          await prefs.setString('location', userLocation);
          await prefs.setString('bio', userBio);
          await prefs.setString('avatar', avatarPath);
        } else {
          _loadFromCache(prefs);
        }
      } catch (e) {
        // API failed, load from cache
        _loadFromCache(prefs);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل البيانات';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _loadFromCache(SharedPreferences prefs) {
    userName = prefs.getString('full_name') ?? "مستخدم Vortex";
    userEmail = prefs.getString('email') ?? "لا يوجد بريد مسجل";
    userPhone = prefs.getString('phone') ?? "لا يوجد هاتف مسجل";
    userLocation = prefs.getString('location') ?? "الموقع غير محدد";
    userBio = prefs.getString('bio') ?? "";
    final avatarPath = prefs.getString('avatar') ?? '';
    userAvatar = ApiService.getFullImageUrl(avatarPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E111A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        // Avatar with profile image
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent,
                          backgroundImage: userAvatar.isNotEmpty
                              ? NetworkImage(userAvatar)
                              : null,
                          child: userAvatar.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        if (userBio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                            child: Text(
                              userBio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            if (result == true) _loadUserData();
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('تعديل البيانات'),
                        ),
                        const SizedBox(height: 30),
                        _buildOption(
                          Icons.phone_android_rounded,
                          "الهاتف: $userPhone",
                          () {},
                        ),
                        _buildOption(
                          Icons.location_on_outlined,
                          "الموقع: $userLocation",
                          () {},
                        ),
                        const Divider(color: Colors.white10, height: 30),
                        _buildOption(Icons.shopping_cart_outlined, "مشترياتي", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                          );
                        }),
                        _buildOption(Icons.inventory_2_outlined, "منتجاتي المعروضة", () {
                        }),
                        _buildOption(Icons.logout_rounded, "تسجيل الخروج", () {
                        }, isDanger: true),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDanger ? Colors.redAccent : Colors.blueAccent,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.redAccent : Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 16,
      ),
    );
  }
}
