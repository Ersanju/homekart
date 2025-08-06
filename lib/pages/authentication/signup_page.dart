import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homekart/pages/authentication/privacy_policy_page.dart';

import 'otp_page.dart';

class SignupPage extends StatefulWidget {
  final String prefilledPhone;

  const SignupPage({super.key, required this.prefilledPhone});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String countryCode = '+91';
  DateTime? _selectedDob;

  void _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<Map<String, String>> fetchAssets() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('app_assets')
            .doc('login_assets')
            .get();

    final data = doc.data() ?? {};
    return {
      'bannerUrl': data['bannerUrl'] ?? '',
      'logoUrl': data['logoUrl'] ?? '',
      'googleLogoUrl': data['googleLogoUrl'] ?? '',
    };
  }

  void _continueToOtp() {
    final phone = widget.prefilledPhone;
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDob == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required.')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OtpPage(
              phone: phone,
              email: phone,
              name: name,
              dob: _selectedDob,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, String>>(
        future: fetchAssets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bannerUrl = snapshot.data!['bannerUrl']!;
          final logoUrl = snapshot.data!['logoUrl']!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: Image.asset("assets/app_assets/login_banner.png")
                    ),
                    Positioned.fill(
                      bottom: -45,
                      child: Align(
                        alignment: Alignment.bottomCenter,
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
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                const Text(
                  'Welcome To Joy-a-Bloom!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Happiness is just a click away',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _pickDob,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CountryCodePicker(
                            onChanged: (code) {
                              countryCode = code.dialCode ?? '+91';
                            },
                            initialSelection: 'IN',
                            favorite: ['+91', 'IN'],
                            showDropDownButton: false,
                            enabled: false, // disables interaction
                          ),
                          Expanded(
                            child: TextField(
                              enabled: false,
                              controller: TextEditingController(
                                text: widget.prefilledPhone.replaceFirst(
                                  '+91',
                                  '',
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Enter 10-digit phone number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF808000),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _continueToOtp,
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            const TextSpan(
                              text:
                                  "By continuing you agree to Joy-a-Bloom’s\n",
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
