import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/cubit/balance_cubit.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedCardType = "Visa";

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAddCardBottomSheet(BuildContext context) {
    final isDark = context.read<ThemeCubit>().isDark;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161823) : Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    l10n?.translate('add_new_card') ?? "إضافة بطاقة جديدة",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cardholder Name
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: _inputDecoration(
                      l10n?.translate('cardholder_name') ?? "اسم صاحب البطاقة",
                      Icons.person_outline,
                      isDark,
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? (l10n?.translate('required_field') ??
                              "يرجى إدخال اسم صاحب البطاقة")
                        : null,
                  ),
                  const SizedBox(height: 15),

                  // Card Number
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberInputFormatter(),
                    ],
                    decoration: _inputDecoration(
                      l10n?.translate('card_number') ?? "رقم البطاقة (16 رقم)",
                      Icons.credit_card_outlined,
                      isDark,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return l10n?.translate('required_field') ??
                            "يرجى إدخال رقم البطاقة";
                      if (v.replaceAll(' ', '').length < 16)
                        return l10n?.translate('invalid_card_number') ??
                            "يجب أن يتكون رقم البطاقة من 16 رقماً";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      // Expiry Date
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _CardExpiryInputFormatter(),
                          ],
                          decoration: _inputDecoration(
                            l10n?.translate('expiry_date') ?? "الصلاحية MM/YY",
                            Icons.calendar_month_outlined,
                            isDark,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return l10n?.translate('required_field') ??
                                  "مطلوب";
                            if (!RegExp(
                              r'^(0[1-9]|1[0-2])\/?([0-9]{2})$',
                            ).hasMatch(v)) {
                              return l10n?.translate('invalid_expiry') ??
                                  "تاريخ غير صالح";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      // CVV
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: _inputDecoration(
                            "CVV",
                            Icons.lock_outline,
                            isDark,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return l10n?.translate('required_field') ??
                                  "مطلوب";
                            if (v.length < 3)
                              return l10n?.translate('invalid_cvv') ??
                                  "3 أرقام";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Card Type Selector
                  DropdownButtonFormField<String>(
                    value: _selectedCardType,
                    dropdownColor: isDark
                        ? const Color(0xFF161823)
                        : Colors.grey.shade100,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: _inputDecoration(
                      l10n?.translate('card_type') ?? "نوع البطاقة",
                      Icons.branding_watermark_outlined,
                      isDark,
                    ),
                    items: const [
                      DropdownMenuItem(value: "Visa", child: Text("Visa")),
                      DropdownMenuItem(
                        value: "Mastercard",
                        child: Text("Mastercard"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCardType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 25),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await context
                              .read<BalanceCubit>()
                              .addCard(
                                cardNumber: _cardNumberController.text,
                                expiryDate: _expiryController.text,
                                cvv: _cvvController.text,
                                cardholderName: _nameController.text,
                                cardType: _selectedCardType,
                              );

                          if (success && context.mounted) {
                            Navigator.pop(ctx);
                            _cardNumberController.clear();
                            _expiryController.clear();
                            _cvvController.clear();
                            _nameController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.translate('card_added') ??
                                      "تم إضافة بطاقتك الائتمانية بنجاح!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        l10n?.translate('save_card') ?? "حفظ البطاقة 💳",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white60 : Colors.black54,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.black54,
        size: 20,
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(height: 0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('payment_methods') ?? "طرق الدفع والبطاقات",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.transparent : Colors.grey.shade200,
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
        child: BlocBuilder<BalanceCubit, BalanceState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            final cards = state.cards;

            if (cards.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_off_outlined,
                        size: 80,
                        color: isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.15),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n?.translate('no_cards') ??
                            "لا توجد بطاقات دفع محفوظة",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.translate('add_card_prompt') ??
                            "أضف بطاقتك الفيزا كارد أو الماستركارد لإتمام عمليات الشراء بسهولة وسرعة.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.add_card, color: Colors.white),
                        label: Text(
                          l10n?.translate('add_card') ?? "إضافة بطاقة جديدة",
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () => _showAddCardBottomSheet(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cards.length + 1,
              itemBuilder: (context, index) {
                if (index == cards.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: Icon(
                        Icons.add,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      label: Text(
                        l10n?.translate('add_another_card') ??
                            "إضافة بطاقة دفع أخرى",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _showAddCardBottomSheet(context),
                    ),
                  );
                }

                final card = cards[index];
                return _buildCreditCard(card);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreditCard(CardModel card) {
    final isVisa = card.cardType.toLowerCase() == 'visa';
    final colors = isVisa
        ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
        : [const Color(0xFFE55D87), const Color(0xFF5FC3E4)];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background reflection effect
          Positioned(
            right: -50,
            bottom: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.cardType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white70,
                      ),
                      onPressed: () => _confirmDeleteCard(card.id),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  card.cardNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "حامل البطاقة",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.cardholderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "الصلاحية",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.expiryDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCard(String cardId) {
    final isDark = context.read<ThemeCubit>().isDark;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1B1B2F)
            : Colors.grey.shade100,
        title: Text(
          l10n?.translate('delete_card') ?? "حذف البطاقة",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          l10n?.translate('delete_card_confirm') ??
              "هل أنت متأكد من رغبتك في حذف بطاقة الدفع هذه؟",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n?.translate('cancel') ?? "إلغاء",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<BalanceCubit>().deleteCard(cardId);
              Navigator.pop(ctx);
            },
            child: Text(l10n?.translate('delete') ?? "حذف"),
          ),
        ],
      ),
    );
  }
}

// Text Formatter for Card Expiry Date (MM/YY)
class _CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Text Formatter for Card Number (16-digit spacing)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != newText.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
