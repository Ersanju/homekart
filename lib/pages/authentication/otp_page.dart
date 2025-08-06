import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../home_page.dart';
import '../../models/cart_item.dart';
import '../../utils/cart_provider.dart';
import '../../utils/wishlist_provider.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String? email;
  final String? name;
  final DateTime? dob;

  const OtpPage({
    super.key,
    required this.phone,
    this.email,
    this.name,
    this.dob,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _otp = '';
  Timer? _resendTimer;
  int _cooldownSeconds = 120;
  bool _canResend = false;
  bool _showOtpSentMessage = true;
  bool _isVerifying = false;
  bool _isSendingOtp = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _requestSmsPermissions();
    _sendOtp();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showOtpSentMessage = false);
    });
    SmsAutoFill().listenForCode();
  }

  @override
  void codeUpdated() {
    setState(() {
      _otp = code ?? '';
      _otpController.text = _otp;
    });
  }

  Future<void> _requestSmsPermissions() async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      _showSnackBar("SMS permission is required for autofill.");
    }
  }

  Future<void> _sendOtp() async {
    if (!_canResend && _verificationId != null) {
      _showSnackBar("Please wait before resending OTP.");
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _canResend = false;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          setState(() => _isSendingOtp = false);
          _showSnackBar(e.code == 'too-many-requests'
              ? "Too many attempts. Try again later."
              : "OTP failed: ${e.message}");
        },
        codeSent: (id, _) {
          setState(() {
            _verificationId = id;
            _isSendingOtp = false;
            _startCooldown();
          });
        },
        codeAutoRetrievalTimeout: (_) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isSendingOtp = false);
      _showSnackBar("Error sending OTP: ${e.toString()}");
    }
  }

  void _startCooldown() {
    _cooldownSeconds = 120;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _verifyOtp() async {
    if (_otp.length != 6 || _verificationId == null) {
      _showSnackBar("Enter a valid 6-digit OTP");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      await _postLoginTasks(userCred.user?.uid);
      _navigateToHome();
    } on FirebaseAuthException {
      _showSnackBar("Invalid OTP or verification failed.");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _postLoginTasks([String? uid]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid ?? user.uid).get();
    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': widget.email,
        'phone': widget.phone,
        'name': widget.name,
        'dob': widget.dob,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await _syncWishlist();
    await _syncCart();
  }

  Future<void> _syncWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final wishlistIds = List<String>.from(doc.data()?['wishlistProductIds'] ?? []);
    context.read<WishlistProvider>().setWishlist(wishlistIds);
  }

  Future<void> _syncCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartList = (await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get())
        .data()?['cartItems'] as List<dynamic>? ??
        [];

    final cartProvider = context.read<CartProvider>();
    await cartProvider.clearCart();
    for (final item in cartList) {
      cartProvider.setQty(
        CartItem.fromJson(item).variant,
        CartItem.fromJson(item).quantity,
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8ED),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(_focusNode),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "OTP sent to your mobile number",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone_android),
                      const SizedBox(width: 8),
                      Text(widget.phone),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Change",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return GestureDetector(
                        onTap: () {
                          FocusScope.of(context).requestFocus(_focusNode);
                          _otpController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _otp.length),
                          );
                        },
                        onLongPress: index == 0
                            ? () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null &&
                              data!.text!.length == 6 &&
                              RegExp(r'^\d{6}$').hasMatch(data.text!)) {
                            setState(() {
                              _otp = data.text!;
                              _otpController.text = _otp;
                            });
                          } else {
                            _showSnackBar("Invalid OTP in clipboard");
                          }
                        }
                            : null,
                        child: Container(
                          width: 45,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _focusNode.hasFocus && _otp.length == index
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.white,
                          ),
                          child: Text(
                            index < _otp.length ? _otp[index] : '',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Offstage(
                    offstage: true,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onChanged: (value) {
                        setState(() {
                          _otp = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Valid for 2 mins."),
                      const Spacer(),
                      InkWell(
                        onTap: _canResend && !_isSendingOtp ? _sendOtp : null,
                        child: Text(
                          _canResend
                              ? "Resend OTP"
                              : "Resend in $_cooldownSeconds sec",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: _canResend && !_isSendingOtp
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_showOtpSentMessage)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6EA),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_box, color: Colors.green),
                          SizedBox(width: 8),
                          Text("OTP sent to mobile number."),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A8E3E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isVerifying ? null : _verifyOtp,
                      child: _isVerifying
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Confirm OTP",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (_isSendingOtp)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
