import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/payment_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import '../widgets/background_widget.dart';

class CheckoutScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final String productTitle;

  const CheckoutScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.productTitle,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderController = TextEditingController();

  String _paymentMethod = 'card';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

  void _processPayment() {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';

    if (_cardNumberController.text.isEmpty ||
        _cardNumberController.text.replaceAll(' ', '').length < 16) {
      Fluttertoast.showToast(
        msg: isEnglish
            ? 'Please enter a valid card number'
            : 'الرجاء إدخال رقم بطاقة صحيح',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_expiryController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: isEnglish
            ? 'Please enter expiry date'
            : 'الرجاء إدخال تاريخ انتهاء الصلاحية',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_cvvController.text.isEmpty || _cvvController.text.length < 3) {
      Fluttertoast.showToast(
        msg: isEnglish ? 'Please enter a valid CVV' : 'الرجاء إدخال CVV صحيح',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    if (_cardholderController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: isEnglish
            ? 'Please enter cardholder name'
            : 'الرجاء إدخال اسم صاحب البطاقة',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    context.read<PaymentCubit>().createPaymentIntent(
      orderId: widget.orderId,
      amount: widget.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish =
        BlocProvider.of<LanguageCubit>(context).state.languageCode == 'en';
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : Colors.grey.shade200,
        title: Text(
          isEnglish ? 'Checkout' : 'الدفع',
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
      body: BlocListener<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state.paymentSuccess) {
            Fluttertoast.showToast(
              msg: isEnglish ? 'Payment successful!' : 'تم الدفع بنجاح!',
              toastLength: Toast.LENGTH_SHORT,
              backgroundColor: Colors.green,
            );
            Navigator.pop(context);
            Navigator.pop(context);
          }
          if (state.errorMessage != null) {
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
                // Order Summary
                Container(
                  padding: EdgeInsets.all(16.sp),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.sp),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Order Summary' : 'ملخص الطلب',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEnglish ? 'Product:' : 'المنتج:',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              widget.productTitle,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEnglish ? 'Amount:' : 'المبلغ:',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            '\$${widget.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: const Color(0xFFA855F7),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.sp),

                // Payment Method Selection
                Text(
                  isEnglish ? 'Payment Method' : 'طريقة الدفع',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.sp),
                RadioListTile<String>(
                  value: 'card',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                  title: Text(
                    isEnglish ? 'Credit/Debit Card' : 'بطاقة ائتمان/خصم',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  activeColor: const Color(0xFFA855F7),
                  tileColor: isDark
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade100,
                ),
                SizedBox(height: 24.sp),

                // Card Details Form
                if (_paymentMethod == 'card') ...[
                  Text(
                    isEnglish ? 'Card Details' : 'تفاصيل البطاقة',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.sp),
                  _buildTextField(
                    label: isEnglish ? 'Cardholder Name' : 'اسم صاحب البطاقة',
                    controller: _cardholderController,
                    isEnglish: isEnglish,
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.sp),
                  _buildTextField(
                    label: isEnglish ? 'Card Number' : 'رقم البطاقة',
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    isEnglish: isEnglish,
                    isDark: isDark,
                    maxLength: 16,
                  ),
                  SizedBox(height: 12.sp),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: isEnglish ? 'Expiry' : 'الصلاحية',
                          controller: _expiryController,
                          hintText: 'MM/YY',
                          isEnglish: isEnglish,
                          isDark: isDark,
                          maxLength: 5,
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      Expanded(
                        child: _buildTextField(
                          label: 'CVV',
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          isEnglish: isEnglish,
                          isDark: isDark,
                          maxLength: 3,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 32.sp),

                // Terms & Conditions
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (_) {},
                      activeColor: const Color(0xFFA855F7),
                    ),
                    Expanded(
                      child: Text(
                        isEnglish
                            ? 'I agree to the terms and conditions'
                            : 'أوافق على الشروط والأحكام',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.sp),

                // Pay Button
                BlocBuilder<PaymentCubit, PaymentState>(
                  builder: (context, state) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B39A0), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(10.sp),
                      ),
                      child: ElevatedButton(
                        onPressed: state.isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 14.sp),
                          minimumSize: Size(double.infinity, 50.sp),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                        ),
                        child: state.isProcessing
                            ? SizedBox(
                                height: 20.sp,
                                width: 20.sp,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEnglish
                                    ? 'Pay \$${widget.amount.toStringAsFixed(2)}'
                                    : 'ادفع \$${widget.amount.toStringAsFixed(2)}',
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
                SizedBox(height: 16.sp),
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
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    required bool isEnglish,
    required bool isDark,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6.sp),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          inputFormatters: maxLength == 16
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ]
              : maxLength == 3
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ]
              : maxLength == 5
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ]
              : null,
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.sp),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.sp),
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
