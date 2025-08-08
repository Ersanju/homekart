import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_address.dart';
import '../../utils/cart_provider.dart';
import 'cart_bottom_bar.dart';
import 'cart_item_widget.dart';
import 'delivery_details_page.dart';
import 'price_details.dart';
import 'step_indicator.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _priceKey = GlobalKey();
  UserAddress? _selectedAddress;

  void _scrollToPriceDetails() {
    final ctx = _priceKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.cartItems;
    final isEmpty = cartItems.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart'), leading: const BackButton()),
      body:
          isEmpty
              ? const Center(
                child: Text(
                  "🛒 Your cart is empty",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          const StepIndicator(
                            currentStep: 1,
                          ), // only cart is green
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              itemCount: cartItems.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final item = cartItems[index];
                                return CartItemWidget(
                                  item: item,
                                  onIncrease:
                                      () => cartProvider.addItem(
                                        item.variant,
                                        productId: item.productId,
                                        productName: item.productName,
                                        productImage: item.productImage,
                                        price: item.price,
                                      ),
                                  onDecrease:
                                      () =>
                                          cartProvider.removeItem(item.variant),
                                );
                              },
                            ),
                          ),

                          // Price Summary
                          PriceDetails(
                            key: _priceKey,
                            productPrice: cartProvider.productPrice,
                            discount: cartProvider.discount,
                            deliveryCharge: cartProvider.deliveryCharge,
                            convenienceCharge: cartProvider.convenienceCharge,
                            showCouponField:
                                false, // don't show coupon field here
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Bar
                  CartBottomBar(
                    total: cartProvider.total, // ✅ Reflects coupon discount now
                    onViewPriceDetails: _scrollToPriceDetails,
                    onProceed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => DeliveryDetailsPage(
                                selectedAddress: _selectedAddress,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
    );
  }
}
