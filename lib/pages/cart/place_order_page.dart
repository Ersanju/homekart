import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../models/order_model.dart';
import '../../models/user_address.dart';
import '../../utils/cart_provider.dart';
import 'order_success_page.dart';

class PlaceOrderPage extends StatefulWidget {
  final UserAddress address;
  final DateTime deliveryDate;
  final String deliveryTime;
  final String paymentMethod;
  final String? razorpayPaymentId;

  const PlaceOrderPage({
    super.key,
    required this.address,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.paymentMethod,
    this.razorpayPaymentId,
  });

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    if (widget.paymentMethod == 'Online Payment' &&
        widget.razorpayPaymentId == null) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _startPayment();
    } else {
      _placeOrder(
        paymentId: widget.razorpayPaymentId ?? 'COD',
        paymentMethod: widget.paymentMethod,
      );
    }
  }

  @override
  void dispose() {
    if (widget.paymentMethod == 'Online Payment' &&
        widget.razorpayPaymentId == null) {
      _razorpay.clear();
    }
    super.dispose();
  }

  void _startPayment() {
    final cart = context.read<CartProvider>();
    final amount = cart.total * 100; // Razorpay expects amount in paise

    final options = {
      'key': 'rzp_test_dvBEXSvWMEkUPN', // <-- Your actual test key here
      'amount': amount,
      'name': 'Joy-a-Bloom',
      'description': 'Celebration Order',
      'prefill': {'contact': '9876543210', 'email': 'test@example.com'},
      'currency': 'INR',
    };

    _razorpay.open(options);
  }

  void _placeOrder({
    required String paymentId,
    required String paymentMethod,
  }) async {
    final cart = context.read<CartProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'guest';
    final orderId = '${DateTime.now().millisecondsSinceEpoch}';

    final order = OrderModel(
      orderId: orderId,
      userId: userId,
      items: cart.cartItems.map((e) => e.toJson()).toList(),
      address: widget.address,
      deliveryDate: widget.deliveryDate,
      deliveryTime: widget.deliveryTime,
      status: paymentMethod == 'Cash on Delivery' ? 'Pending' : 'Paid',
      paymentMethod: paymentMethod,
      paymentId: paymentId,
      amount: cart.total.toDouble(),
      createdAt: Timestamp.now(),
    );

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .set(order.toJson());

    cart.clearCart();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderId)),
      (route) => false,
    );
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _placeOrder(
      paymentId: response.paymentId ?? 'unknown',
      paymentMethod: 'Online Payment',
    );
  }

  void _handleError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment failed. Please try again.")),
    );
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet selected: ${response.walletName}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
