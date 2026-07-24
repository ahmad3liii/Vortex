import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/payment_cubit.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentCubit>().getPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('my_orders') ?? 'مشترياتي',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (state.paymentHistory.isEmpty) {
              return _buildEmptyState(l10n, isDark);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.paymentHistory.length,
              itemBuilder: (context, index) {
                final order = state.paymentHistory[index];
                return _buildOrderTile(order, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderTile(PaymentModel order, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: ApiService.getFullImageUrl(order.productImage),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white10,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.shopping_bag_rounded,
                  color: isDark ? Colors.blueAccent : Colors.blueAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.statusText,
                  style: TextStyle(
                    color: order.isSuccessful
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${order.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.translate('no_purchases') ?? 'لا توجد مشتريات سابقة',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
