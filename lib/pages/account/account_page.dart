import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:homekart/pages/account/reminder_list_page.dart';
import 'package:homekart/pages/account/saved_addresses.dart';
import 'package:homekart/pages/account/share_feedback_page.dart';
import 'package:homekart/pages/account/wishlist_page.dart';
import 'package:provider/provider.dart';

import '../../home_page.dart';
import '../../utils/app_auth_provider.dart';
import '../../utils/app_util.dart';
import '../../utils/cart_provider.dart';
import '../../utils/wishlist_provider.dart';
import '../authentication/login_page.dart';
import '../authentication/privacy_policy_page.dart';
import 'become_partner_page.dart';
import 'bulk_order_page.dart';
import 'chat_with_us.dart';
import 'decor_info_page.dart';
import 'edit_profile_page.dart';
import 'fyq_page.dart';
import 'my_order_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _localImage;
  String? _firestoreImageUrl;
  String _name = 'Loading...';
  String _email = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }


  // In _AccountPageState
  Future<void> _loadUserData() async {
    try {
      print("Attempting to read AppAuthProvider in AccountPage...");
      final authProvider = context.read<AppAuthProvider>();
      print("Successfully read AppAuthProvider: ${authProvider.isLoggedIn}");
      final user = authProvider.user;
      if (user == null) {
        print("User is null in _loadUserData");
        return;
      }

      // ... rest of your existing _loadUserData logic ...
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (mounted) { // Good practice to check mounted before setState
          setState(() {
            _name = data['name'] ?? '';
            _email = data['email'] ?? '';
            _firestoreImageUrl = data['profileImageUrl'];
          });
        }
      } else {
        print("User document does not exist for UID: ${user.uid}");
      }
    } catch (e, s) {
      print("ERROR in _loadUserData reading AppAuthProvider: $e");
      print(s); // Print stack trace
    }
  }


  void _showImagePreviewDialog() {
    if (_firestoreImageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: InteractiveViewer(
              child: Image.network(
                _firestoreImageUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xfffafaf6),
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xfffafaf6),
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileTile(user),
            const SizedBox(height: 20),
            _buildAccountOptions(isLoggedIn),
            const Divider(height: 30, thickness: 5),
            _buildAccountTileSection(context),
            const Divider(height: 30, thickness: 5),
            _buildEnquiriesSection(context),
            const Divider(height: 30, thickness: 5),
            const SizedBox(height: 15),
            _buildFooterSection(),
            const SizedBox(height: 15),
            _buildAuthButton(context, isLoggedIn),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(User? user) {
    if (user == null) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        child: const ListTile(
          leading: CircleAvatar(radius: 30, child: Icon(Icons.person)),
          title: Text("Guest"),
          subtitle: Text("Please login to see your profile"),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      );
    }

    ImageProvider<Object>? imageProvider;
    if (_firestoreImageUrl?.isNotEmpty == true) {
      imageProvider = CachedNetworkImageProvider(_firestoreImageUrl!);
    } else if (_localImage != null) {
      imageProvider = FileImage(_localImage!);
    } else {
      imageProvider = null; // Will use fallback icon
    }

    return ListTile(
      leading: GestureDetector(
        onTap: _showImagePreviewDialog,
        child: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: imageProvider,
          child:
              imageProvider == null
                  ? const Icon(
                    Icons.account_circle,
                    size: 48,
                    color: Colors.grey,
                  )
                  : null,
        ),
      ),
      title: Text(_name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_email),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          );
          _loadUserData(); // Refresh after editing
        },
      ),
    );
  }

  Widget _buildAccountOptions(bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.8,
        children: [
          _AccountButton(
            icon: Icons.local_shipping_outlined,
            label: "My Orders",
            onPressed: () async {
              final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
              if (!isLoggedIn) return;

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyOrdersPage(userId: FirebaseAuth.instance.currentUser!.uid,)),
              );
            },
          ),

          _AccountButton(
            icon: Icons.notifications_outlined,
            label: "Reminders",
            onPressed: () async {
              final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
              if (!isLoggedIn) return;

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReminderListPage()),
              );
            },
          ),
          _AccountButton(
            icon: Icons.chat_bubble_outline,
            label: "Chat With Us",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatWithUs()),
              );
            },
          ),
          _AccountButton(
            icon: Icons.favorite_border,
            label: "Wishlist",
            onPressed: () async {
              final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
              if (!isLoggedIn) return;

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WishlistPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTileSection(BuildContext context) {
    return Column(
      children: [
        const _AccountTile(
          icon: Icons.account_balance_wallet,
          label: "Joy-a-bloom Cash ₹0",
          trailing: "New",
        ),
        _buildDivider(),
        _AccountTile(
          icon: Icons.person_outline,
          label: "Personal Information",
          onTap: () async {
            final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
            if (!isLoggedIn) return;

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProfilePage()),
            );
          },
        ),
        _buildDivider(),
        _AccountTile(
          icon: Icons.location_on_outlined,
          label: "Saved Addresses",
          onTap: () async {
            final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
            if (!isLoggedIn) return;

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SavedAddressesPage()),
            );
          },
        ),
        _buildDivider(),
        _AccountTile(
          icon: Icons.help_outline,
          label: "FAQ's",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FYQPage()),
            );
          },
        ),
        _buildDivider(),
        const _AccountTile(icon: Icons.delete_outline, label: "Delete Account"),
      ],
    );
  }

  Widget _buildEnquiriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Enquiries",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.celebration_outlined,
          label: "Birthday/ Wedding Decor",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DecorInfoPage()),
            );
          },
        ),
        _buildDivider(),
        _AccountTile(
          icon: Icons.work_outline,
          label: "Corporate Gifts/ Bulk Orders",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BulkOrderPage()),
            );
          },
        ),
        _buildDivider(),
        _AccountTile(
          icon: Icons.home_rounded,
          label: "Become a Partner",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BecomePartnerPage()),
            );
          },
        ),
        _buildDivider(),
        _AccountTile(
          icon: Icons.feedback,
          label: 'Share app feedback',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              isScrollControlled: true,
              builder:
                  (_) => const FractionallySizedBox(
                    heightFactor: 0.5,
                    child: FeedbackForm(), // defined below
                  ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyPage(),
              ),
            );
          },
          child: const Text(
            "Privacy Policy",
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const Text('App Version: 5.1.1', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() => Divider(
    thickness: 0.5,
    indent: 16,
    endIndent: 16,
    color: Colors.grey.shade300,
  );

  Widget _buildAuthButton(BuildContext context, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () async {
          if (isLoggedIn) {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
            );
            if (confirm == true) {
              final cartProvider = Provider.of<CartProvider>(
                context,
                listen: false,
              );
              final wishlistProvider = Provider.of<WishlistProvider>(
                context,
                listen: false,
              );

              await FirebaseAuth.instance.signOut();
              cartProvider.clearCart(); // ✅ clear cart
              wishlistProvider.setWishlist([]); // ✅ clear wishlist
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        },
        icon: Icon(
          isLoggedIn ? Icons.logout : Icons.login,
          color: Colors.white,
        ),
        label: Text(isLoggedIn ? "Logout" : "Login"),
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoggedIn ? const Color(0xFFFF7043) : Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AccountButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _AccountTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing:
          trailing != null
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trailing!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
              : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
