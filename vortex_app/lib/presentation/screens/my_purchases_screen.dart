import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/cubit/order_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import '../widgets/background_widget.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<OrderCubit>().fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appLocalizations?.translate('my_orders') ?? 'الطلبات',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Color(0xFF6C63FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  text:
                      appLocalizations?.translate('my_purchases') ??
                      '🛍️  مشترياتي',
                ),
                Tab(
                  text:
                      appLocalizations?.translate('sales_orders') ??
                      '📦  طلبات البيع',
                ),
              ],
            ),
          ),
        ),
      ),
      body: BackgroundWidget(
        child: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildMyPurchasesTab(
                  state.myPurchases,
                  appLocalizations,
                  isDark,
                ),
                _buildSalesOrdersTab(
                  state.salesOrders,
                  context,
                  appLocalizations,
                  isDark,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Tab 1: My Purchases ──────────────────────────────────────────────
  Widget _buildMyPurchasesTab(
    List<OrderModel> orders,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    if (orders.isEmpty) {
      return _emptyState(
        icon: Icons.shopping_bag_outlined,
        title: l10n?.translate('no_purchases') ?? 'لم تقم بشراء أي منتجات بعد',
        subtitle:
            l10n?.translate('browse_market') ??
            'تصفّح السوق واشترِ أول منتج بالفيزا كارد!',
        isDark: isDark,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) =>
          _buildOrderCard(orders[i], isBuyer: true, l10n: l10n, isDark: isDark),
    );
  }

  // ─── Tab 2: Incoming Sales Orders ────────────────────────────────────
  Widget _buildSalesOrdersTab(
    List<OrderModel> orders,
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    if (orders.isEmpty) {
      return _emptyState(
        icon: Icons.storefront_outlined,
        title: l10n?.translate('no_sales') ?? 'لا توجد طلبات بيع واردة بعد',
        subtitle:
            l10n?.translate('when_sold') ??
            'عندما يشتري أحد منتجاتك سيظهر الطلب هنا.',
        isDark: isDark,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildOrderCard(
        orders[i],
        isBuyer: false,
        context: context,
        l10n: l10n,
        isDark: isDark,
      ),
    );
  }

  Widget _buildOrderCard(
    OrderModel order, {
    required bool isBuyer,
    BuildContext? context,
    AppLocalizations? l10n,
    required bool isDark,
  }) {
    final statusInfo = _statusInfo(order.status, l10n);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    order.productImage,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 75,
                      height: 75,
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productTitle,
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
                        isBuyer
                            ? '${l10n?.translate('seller') ?? 'البائع'}: ${order.sellerName}'
                            : '${l10n?.translate('buyer') ?? 'المشتري'}: ${order.buyerName}',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${order.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isDark ? Colors.blueAccent : Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (statusInfo['color'] as Color).withOpacity(
                                0.15,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (statusInfo['color'] as Color)
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusInfo['icon'] as IconData,
                                  color: statusInfo['color'] as Color,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusInfo['label'] as String,
                                  style: TextStyle(
                                    color: statusInfo['color'] as Color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
              ],
            ),
          ),

          // Seller action: update status
          if (!isBuyer &&
              order.status != 'delivered' &&
              order.status != 'cancelled')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildSellerActions(order, context!, l10n, isDark),
            ),

          // Order date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerActions(
    OrderModel order,
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
  ) {
    String nextStatus = '';
    String nextLabel = '';
    IconData nextIcon = Icons.check;
    Color nextColor = Colors.blueAccent;

    if (order.status == 'pending') {
      nextStatus = 'processing';
      nextLabel = l10n?.translate('start_processing') ?? 'بدء التجهيز';
      nextIcon = Icons.inventory_2_outlined;
      nextColor = Colors.orangeAccent;
    } else if (order.status == 'processing') {
      nextStatus = 'shipped';
      nextLabel = l10n?.translate('shipped') ?? 'تم الشحن';
      nextIcon = Icons.local_shipping_outlined;
      nextColor = Colors.blueAccent;
    } else if (order.status == 'shipped') {
      nextStatus = 'delivered';
      nextLabel = l10n?.translate('confirm_delivery') ?? 'تأكيد التسليم';
      nextIcon = Icons.check_circle_outline_rounded;
      nextColor = Colors.greenAccent;
    }

    if (nextStatus.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: nextColor.withOpacity(0.15),
              foregroundColor: nextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: nextColor.withOpacity(0.4)),
              ),
              elevation: 0,
            ),
            icon: Icon(nextIcon, size: 16),
            label: Text(
              nextLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              _updateOrderStatus(order.id, nextStatus, context);
            },
          ),
        ),
      ],
    );
  }

  // دالة لتحديث حالة الطلب عبر OrderCubit
  void _updateOrderStatus(
    String orderId,
    String newStatus,
    BuildContext context,
  ) {
    final orderCubit = context.read<OrderCubit>();
    final isDark = context.read<ThemeCubit>().isDark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1B1B2F)
            : Colors.grey.shade100,
        title: Text(
          'تأكيد التحديث',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'هل أنت متأكد من تحديث حالة الطلب إلى "${_getStatusName(newStatus)}"?',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await orderCubit.updateOrderStatus(int.parse(orderId), newStatus);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم تحديث حالة الطلب إلى: ${_getStatusName(newStatus)}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'processing':
        return 'قيد التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التسليم';
      default:
        return status;
    }
  }

  Map<String, dynamic> _statusInfo(String status, AppLocalizations? l10n) {
    switch (status) {
      case 'pending':
        return {
          'label': l10n?.translate('pending') ?? 'قيد الانتظار',
          'color': Colors.orangeAccent,
          'icon': Icons.hourglass_top_rounded,
        };
      case 'processing':
        return {
          'label': l10n?.translate('processing') ?? 'قيد التجهيز',
          'color': Colors.blueAccent,
          'icon': Icons.inventory_2_outlined,
        };
      case 'shipped':
        return {
          'label': l10n?.translate('shipped') ?? 'تم الشحن',
          'color': Colors.purple,
          'icon': Icons.local_shipping_outlined,
        };
      case 'delivered':
        return {
          'label': l10n?.translate('delivered') ?? 'تم التسليم ✓',
          'color': Colors.greenAccent,
          'icon': Icons.check_circle_outline_rounded,
        };
      case 'cancelled':
        return {
          'label': l10n?.translate('cancelled') ?? 'ملغي',
          'color': Colors.redAccent,
          'icon': Icons.cancel_outlined,
        };
      default:
        return {
          'label': status,
          'color': Colors.white54,
          'icon': Icons.info_outline,
        };
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
