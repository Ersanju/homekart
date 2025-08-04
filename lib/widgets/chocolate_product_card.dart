import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../utils/cart_provider.dart';

class ChocolateProductCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final VoidCallback onTap;
  final VoidCallback onVariantTap;

  const ChocolateProductCard({
    super.key,
    required this.productData,
    required this.onTap,
    required this.onVariantTap,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final imageUrl =
        (productData['imageUrls'] as List?)?.first ??
            "https://via.placeholder.com/150";
    final name = productData['name'] ?? '';

    final chocolateAttr = productData['extraAttributes']?['chocolateAttribute'];
    final variant = (chocolateAttr?['variants'] as List?)?.first;
    if (variant == null) return const SizedBox.shrink();

    final price = variant['price'] ?? 0;
    final oldPrice = variant['oldPrice'];
    final weightInGrams = variant['weightInGrams']?.toInt() ?? 0;
    final variantId = "${productData['id']}_${variant['sku']}";
    final cartQty = cartProvider.getQty(variantId);

    String? discountLabel;
    if (oldPrice != null && oldPrice > price) {
      final discountPercent = ((oldPrice - price) / oldPrice) * 100;
      discountLabel =
      discountPercent >= 10
          ? "${discountPercent.toStringAsFixed(0)}% OFF"
          : "₹${(oldPrice - price).toStringAsFixed(0)} OFF";
    }

    return SizedBox(
      width: 120,
      height: 210, // Fix card height
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(128, 128, 128, 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                GestureDetector(
                  onTap: onTap,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (discountLabel != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              discountLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price & Name
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "₹${price.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (oldPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                "₹${oldPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ), // Push variant row to bottom
                Spacer(),
                // Variant Selector
                GestureDetector(
                  onTap: onVariantTap,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Row(
                      children: [
                        Text(
                          "${weightInGrams}g",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.green,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
          ),

          // Cart Actions
          Positioned(
            top: 95,
            right: 1,
            child:
            cartQty == 0
                ? GestureDetector(
              onTap:
                  () => cartProvider.addItem(
                variantId,
                productId: productData['id'],
                productName: productData['name'],
                productImage: imageUrl,
                price: (variant['price'] ?? 0).toDouble(),
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.green, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                  color: Colors.green,
                ),
              ),
            )
                : Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => cartProvider.removeItem(variantId),
                    child: const Icon(
                      Icons.remove,
                      size: 20,
                      color: Colors.green,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '$cartQty',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () => cartProvider.addItem(
                      variantId,
                      productId: productData['id'],
                      productName: productData['name'],
                      productImage: imageUrl,
                      price: (variant['price'] ?? 0).toDouble(),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showVariantsBottomSheet(
      BuildContext context,
      Product product,
      ) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final variants =
        product.extraAttributes?.chocolateAttribute?.variants ?? [];

    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.7,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  child: Column(
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Variant list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: variants.length,
                          itemBuilder: (context, index) {
                            final v = variants[index];
                            final variantId = "${product.id}_${v.sku}";
                            final qty = cartProvider.getQty(variantId);
                            final pricePerGram =
                            v.weightInGrams > 0
                                ? v.price / v.weightInGrams
                                : 0.0;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      product.imageUrls.first,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      "₹${v.price.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (v.oldPrice != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          "₹${v.oldPrice!.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                            decoration:
                                            TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${v.weightInGrams.toInt()} g",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "₹${pricePerGram.toStringAsFixed(2)} / g",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing:
                                qty == 0
                                    ? TextButton(
                                  onPressed: () {
                                    cartProvider.addItem(
                                      variantId,
                                      productId: product.id,
                                      productName: product.name,
                                      productImage:
                                      product.imageUrls.first,
                                      price: v.price,
                                    );
                                    setState(() {});
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                    Colors.green.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    "Add",
                                    style: TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                                    : Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    border: Border.all(
                                      color: Colors.green,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      4,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          cartProvider.removeItem(
                                            variantId,
                                          );
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          Icons.remove,
                                          size: 24,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          cartProvider.addItem(
                                            variantId,
                                            productId: product.id,
                                            productName: product.name,
                                            productImage:
                                            product.imageUrls.first,
                                            price: v.price,
                                          );
                                          setState(() {});
                                        },
                                        child: const Icon(
                                          Icons.add,
                                          size: 24,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 10,
                            ),
                            child: Text(
                              "Done",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
