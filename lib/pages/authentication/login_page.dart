import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homekart/pages/authentication/privacy_policy_page.dart';
import 'package:homekart/pages/authentication/signup_page.dart';

import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  String countryCode = '+91';

  Future<Map<String, String>> fetchLoginAssets() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('app_assets')
            .doc('login_assets')
            .get();

    final data = doc.data();
    return {
      'bannerUrl':
          data?['bannerUrl'] ??
          'https://via.placeholder.com/600x400.png?text=Banner',
      'logoUrl':
          data?['logoUrl'] ??
          'https://via.placeholder.com/100x100.png?text=Logo',
      'googleLogoUrl':
          data?['googleLogoUrl'] ??
          'https://via.placeholder.com/100x100.png?text=Logo',
    };
  }

  Future<void> _handleContinue() async {
    final phone = _phoneController.text.trim();

    // Validate phone number length (basic check)
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 10-digit phone number")),
      );
      return;
    }

    final fullPhone = '+91$phone'; // Add country code

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: fullPhone)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpPage(phone: fullPhone)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignupPage(prefilledPhone: fullPhone),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: FutureBuilder<Map<String, String>>(
        future: fetchLoginAssets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bannerUrl = snapshot.data!['bannerUrl']!;
          final logoUrl = snapshot.data!['logoUrl']!;

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Banner with logo overlay
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.asset("assets/app_assets/login_banner.png"),
                      Positioned(
                        bottom: -45,
                        left: MediaQuery.of(context).size.width / 2 - 45,
                        child: Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          shadowColor: Colors.black45,
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.asset("assets/app_assets/app_logo.png")
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    "Sign Up / Login to HomeKart!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "For a personalized experience & faster checkout",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                color: Colors.grey.shade100,
                              ),
                              alignment: Alignment.center,
                              child: CountryCodePicker(
                                onChanged: (code) {
                                  countryCode = code.dialCode ?? '+91';
                                },
                                initialSelection: 'IN',
                                favorite: ['+91', 'IN'],
                                showDropDownButton: false,
                                enabled: false,
                                padding: EdgeInsets.zero,
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.start,
                              // aligned to the left
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'monospace',
                                letterSpacing: 3.0,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter phone number',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 2.5,
                                ),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    height: 50,
                    width: 340,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF808000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleContinue,
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(
                          text: "By continuing you agree to Joy-a-Bloom’s\n",
                        ),
                        TextSpan(
                          text: "Terms & Conditions & Privacy Policy",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
