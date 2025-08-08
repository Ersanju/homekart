import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../models/user_address.dart';
import 'place_order_page.dart';

class PaymentPage extends StatefulWidget {
  final UserAddress selectedAddress;
  final DateTime selectedDate;
  final String selectedTimeSlot;

  const PaymentPage({
    super.key,
    required this.selectedAddress,
    required this.selectedDate,
    required this.selectedTimeSlot,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPaymentMethod = 'cod';
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentOption(title: 'Cash on Delivery', value: 'cod'),
            const SizedBox(height: 12),
            _buildPaymentOption(
              title: 'Pay with Razorpay (UPI/Card)',
              value: 'razorpay',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handlePay,
                child: Text(
                  selectedPaymentMethod == 'cod'
                      ? 'Place Order (COD)'
                      : 'Pay with Razorpay',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({required String title, required String value}) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor:
          selectedPaymentMethod == value ? Colors.blue.shade50 : Colors.white,
      title: Text(title),
      leading: Radio<String>(
        value: value,
        groupValue: selectedPaymentMethod,
        onChanged: (val) {
          setState(() {
            selectedPaymentMethod = val!;
          });
        },
      ),
    );
  }

  void _handlePay() {
    if (selectedPaymentMethod == 'cod') {
      _goToPlaceOrder(paymentMethod: 'Cash on Delivery', paymentId: null);
    } else {
      _startRazorpayPayment();
    }
  }

  void _startRazorpayPayment() {
    var options = {
      'key': 'rzp_test_dvBEXSvWMEkUPN', // ✅ Your Razorpay test key
      'amount': 10000, // Amount in paise (₹100.00)
      'currency': 'INR',
      'name': 'Joy-a-Bloom',
      'description': 'Order Payment',
      'prefill': {
        'contact': '9876543210', // You can replace with actual user data
        'email': 'customer@example.com',
      },
      'theme': {'color': '#F37254'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment Successful')));
    _goToPlaceOrder(paymentMethod: 'Razorpay', paymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Wallet selected: ${response.walletName}')),
    );
  }

  void _goToPlaceOrder({required String paymentMethod, String? paymentId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PlaceOrderPage(
              address: widget.selectedAddress,
              deliveryDate: widget.selectedDate,
              deliveryTime: widget.selectedTimeSlot,
              paymentMethod: paymentMethod,
              razorpayPaymentId: paymentId,
            ),
      ),
    );
  }
}
