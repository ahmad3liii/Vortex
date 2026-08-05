import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/screens/home/home.dart';
import '../../logic/cubit/nav_cubit.dart';
import '../../logic/cubit/notification_cubit.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'my_purchases_screen.dart';
import 'notifications_screen.dart';
import 'package:vortex_market/data/models/app_models.dart';
import '../widgets/background_widget.dart'; // ✅ استيراد

class MainNavigationScreen extends StatelessWidget {
  MainNavigationScreen({super.key});

  // ✅ تحويل _pages إلى getter لإعادة إنشاء الصفحات عند التغيير
  List<Widget> get _pages => [
    HomeScreen(),
    SearchPage(),
    MyPurchasesScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, int>(
      builder: (context, currentIndex) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildVortexAppBar(context, currentIndex),
          body: BackgroundWidget(
            // ✅ استبدال الخلفية الثابتة
            child: IndexedStack(index: currentIndex, children: _pages),
          ),
          bottomNavigationBar: _buildBottomNav(context, currentIndex),
        );
      },
    );
  }

  PreferredSizeWidget _buildVortexAppBar(BuildContext context, int index) {
    final appLocalizations = AppLocalizations.of(context);

    // ✅ ترجمة عناوين الصفحات حسب اللغة
    List<String> titles = [
      appLocalizations?.home ?? "الرئيسية",
      appLocalizations?.search ?? "البحث",
      appLocalizations?.purchases ?? "مشترياتي",
      appLocalizations?.profile ?? "حسابي",
    ];

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        titles[index],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        BlocBuilder<NotificationCubit, List<NotificationModel>>(
          builder: (context, notifications) {
            final count = notifications.length;
            return IconButton(
              icon: Badge(
                label: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                isLabelVisible: count > 0,
                backgroundColor: Colors.redAccent,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final appLocalizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0C29),
        currentIndex: currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white38,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => context.read<NavCubit>().changePage(index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: appLocalizations?.home ?? "الرئيسية",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: appLocalizations?.search ?? "البحث",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            activeIcon: const Icon(Icons.shopping_bag),
            label: appLocalizations?.purchases ?? "مشترياتي",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: appLocalizations?.profile ?? "حسابي",
          ),
        ],
      ),
    );
  }
}
