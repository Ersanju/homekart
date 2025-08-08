import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep; // 1 = Cart, 2 = Delivery, 3 = Payment

  const StepIndicator({super.key, this.currentStep = 1});

  @override
  Widget build(BuildContext context) {
    Color getColor(int step) =>
        currentStep >= step ? Colors.green : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.shopping_cart, color: getColor(1)),
          Container(height: 4, width: 64, color: getColor(2)),
          Icon(Icons.local_shipping_outlined, color: getColor(2)),
          Container(height: 4, width: 64, color: getColor(3)),
          Icon(Icons.currency_rupee, color: getColor(3)),
        ],
      ),
    );
  }
}
