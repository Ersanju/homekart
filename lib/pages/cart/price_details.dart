import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/cart_provider.dart';

class PriceDetails extends StatefulWidget {
  final int productPrice;
  final int discount;
  final int deliveryCharge;
  final int convenienceCharge;
  final bool showCouponField; // NEW

  const PriceDetails({
    super.key,
    required this.productPrice,
    required this.discount,
    required this.deliveryCharge,
    required this.convenienceCharge,
    this.showCouponField = false, // default false
  });

  @override
  State<PriceDetails> createState() => _PriceDetailsState();
}

class _PriceDetailsState extends State<PriceDetails> {
  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;

  void _applyCoupon() {
    final code = _couponController.text.trim();
    context.read<CartProvider>().applyCoupon(code);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final couponDiscount = cartProvider.couponDiscount;
    var couponMessage = cartProvider.couponMessage;
    final productPrice = widget.productPrice;
    final discount = widget.discount;

    int subtotal = productPrice - discount - couponDiscount;
    int finalAmount =
        (subtotal > 0 ? subtotal : 0) +
        widget.deliveryCharge +
        widget.convenienceCharge;

    return Card(
      margin: const EdgeInsets.all(10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            if (widget.showCouponField) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coupon TextField
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        hintText: "Enter Coupon Code",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Apply / Remove Button
                  SizedBox(
                    height: 48,
                    child:
                        _couponApplied
                            ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _couponController.clear();
                                  _couponApplied = false;
                                  couponMessage = '';
                                });
                                // TODO: handle coupon removal logic
                              },
                              child: const Text("Remove"),
                            )
                            : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              onPressed: _applyCoupon,
                              child: const Text("Apply"),
                            ),
                  ),
                ],
              ),

              if (couponMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      couponMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            couponDiscount > 0
                                ? Colors.green
                                : Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
            ],
            _priceRow("Total Product Price", "₹$productPrice"),
            _priceRow("Discount On MRP", "-₹$discount", color: Colors.green),
            if (couponDiscount > 0)
              _priceRow(
                "Coupon Discount",
                "-₹$couponDiscount",
                color: Colors.green,
              ),
            _priceRow("Delivery Charges", "₹${widget.deliveryCharge}"),
            _priceRow("Convenience Charge", "₹${widget.convenienceCharge}"),
            const Divider(),
            _priceRow("Total Amount", "₹$finalAmount", isBold: true),
            const SizedBox(height: 10),

            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade50,
              child: Text(
                (discount + couponDiscount) > 0
                    ? "🎉 You are saving ₹${discount + couponDiscount} on this order"
                    : productPrice < 500
                    ? "🛍️ Add more items worth ₹${500 - productPrice} to unlock discounts & free delivery"
                    : "✅ You are eligible for free delivery, add more for additional discounts!",
                style: TextStyle(
                  color:
                      (discount + couponDiscount) > 0
                          ? Colors.green
                          : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String title,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
