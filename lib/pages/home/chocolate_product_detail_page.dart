import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../utils/cart_provider.dart';
import '../../widgets/chocolate_product_card.dart';

class ChocolateProductDetailPage extends StatefulWidget {
  final String productId;

  const ChocolateProductDetailPage({super.key, required this.productId});

  @override
  State<ChocolateProductDetailPage> createState() =>
      _ChocolateProductDetailPageState();
}

class _ChocolateProductDetailPageState
    extends State<ChocolateProductDetailPage> {
  Product? product;
  List<Product> similarProducts = [];
  int selectedPackIndex = 0;
  bool isLoading = true;
  bool isLoadingSimilar = true;

  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  void _initializeCartStatus() {
    final variants = product!.extraAttributes?.chocolateAttribute?.variants;
    if (variants == null || selectedPackIndex >= variants.length) return;

    final sku = variants[selectedPackIndex].sku;
    final variantId = "${product!.id}_$sku";

    final cartProvider = context.read<CartProvider>();
    setState(() {
      isInCart = cartProvider.getQty(variantId) > 0;
    });
  }

  Future<void> fetchProduct() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .get();

      if (doc.exists) {
        product = Product.fromJson(doc.data()!);
        setState(() => isLoading = false);

        // ✅ Now call this safely, after product is loaded
        _initializeCartStatus();

        fetchSimilarProducts(product!.categoryId);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSimilarProducts(String categoryId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('categoryId', isEqualTo: categoryId)
            .get();

    final products =
        snapshot.docs
            .map((doc) => Product.fromJson(doc.data()))
            .where((p) => p.id != widget.productId)
            .toList();

    setState(() {
      similarProducts = products;
      isLoadingSimilar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (product == null) {
      return const Scaffold(body: Center(child: Text("Product not found")));
    }

    final variants = product!.extraAttributes?.chocolateAttribute?.variants;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: const [
          Icon(Icons.search, color: Colors.black),
          SizedBox(width: 16),
          Icon(Icons.share, color: Colors.black),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildProductHeader(product!),
            Image.network(
              product!.imageUrls.first,
              height: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            buildPackSelector(product!, variants ?? []),
            const Divider(height: 32, thickness: 4),
            buildSection("About the Product", product!.productDescription),
            const Divider(thickness: 4),
            buildSection("Care Instructions", product!.careInstruction),
            const Divider(),
            buildSection("Delivery Information", product!.deliveryInformation),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Ratings & Reviews",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                "4.2 ★ (9884 ratings and 108 reviews)",
                style: TextStyle(color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            if (!isLoadingSimilar) buildSimilarProductsSection(similarProducts),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomAddToCartButton(),
    );
  }

  Widget buildBottomAddToCartButton() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final variants = product!.extraAttributes?.chocolateAttribute?.variants;
    final selectedVariant = variants?[selectedPackIndex];
    if (selectedVariant == null) return const SizedBox.shrink();

    final productId = product!.id;
    final productName = product!.name;
    final imageUrl = product!.imageUrls.first;
    final price = selectedVariant.price;
    final sku = selectedVariant.sku;
    final variantId = "${productId}_$sku";
    final isInCart = cartProvider.getQty(variantId) > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isInCart ? Colors.orange : Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () async {
          if (isInCart) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Text("testdata")),
            );
          } else {
            cartProvider.addItem(
              variantId,
              productId: productId,
              productName: productName,
              productImage: imageUrl,
              price: price,
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Added to cart")));
            // This must be in a StatefulWidget
            if (mounted) setState(() {});
          }
        },
        child: Text(
          isInCart ? "Go to Cart" : "Add to Cart",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildProductHeader(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                product.extraAttributes!.chocolateAttribute!.brand,
                style: const TextStyle(color: Colors.green),
              ),
              const Icon(
                Icons.arrow_right_outlined,
                size: 30,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 11, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      "4.4",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "9884 ratings & 108 reviews",
                style: TextStyle(color: Colors.green, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPackSelector(Product product, List<dynamic> variants) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Pack sizes:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              Text(
                " ${variants[selectedPackIndex].weightInGrams.toInt()}g",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: variants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final v = variants[index];
                final isSelected = selectedPackIndex == index;
                final pricePerGram = v.price / v.weightInGrams;

                return GestureDetector(
                  onTap: () => setState(() => selectedPackIndex = index),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.white70
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${v.weightInGrams.toInt()} g",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "₹${v.price}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              " (₹${pricePerGram.toStringAsFixed(2)}/g)",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("• $line"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSimilarProductsSection(List<Product> similarProducts) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Similar Products",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: similarProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = similarProducts[index];

                return SizedBox(
                  width: 120, // adjust width if needed
                  child: ChocolateProductCard(
                    productData: product.toJson(),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChocolateProductDetailPage(
                                productId: product.id,
                              ),
                        ),
                      );
                    },
                    onVariantTap: () {
                      ChocolateProductCard.showVariantsBottomSheet(
                        context,
                        product,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
