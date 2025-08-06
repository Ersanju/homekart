import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homekart/pages/home/product_detail_page.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../utils/wishlist_provider.dart';
import '../../widgets/cake_product_card.dart';
import '../../widgets/chocolate_product_card.dart';
import 'chocolate_product_detail_page.dart';

class ProductsByCategoryGridPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ProductsByCategoryGridPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ProductsByCategoryGridPage> createState() =>
      _ProductsByCategoryGridPageState();
}

class _ProductsByCategoryGridPageState
    extends State<ProductsByCategoryGridPage> {
  Future<List<Product>>? _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = fetchProductsByTopCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body:
          _futureProducts == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<Product>>(
                future: _futureProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    debugPrint('Product load error: ${snapshot.error}');
                    return const Center(child: Text("Failed to load products"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }

                  final products = snapshot.data!;
                  final isChocolate = widget.categoryId == 'cat_chocolate';

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.53,
                          ),
                      itemBuilder: (_, index) {
                        final product = products[index];

                        if (isChocolate) {
                          return ChocolateProductCard(
                            productData: product.toJson(),
                            onTap: () {
                              Navigator.push(
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
                          );
                        } else {
                          return CakeProductCard(
                            productData: product.toJson(),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProductDetailPage(
                                        productId: product.id,
                                      ),
                                ),
                              );
                            },
                            isWishlisted: wishlistProvider.isWishlisted(
                              product.id,
                            ),
                            onWishlistToggle: () {
                              setState(() {
                                wishlistProvider.toggleWishlist(product.id);
                              });
                            },
                          );
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }

  Future<List<Product>> fetchProductsByTopCategory(String categoryId) async {
    try {
      List<Product> allProducts = [];

      // 1. Try fetching by categoryId
      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('categoryId', isEqualTo: categoryId)
              .get();

      allProducts =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromJson(data);
          }).toList();

      // 2. If empty, fetch by tag (e.g., if categoryId == cat_anniversary → tag: anniversary)
      if (allProducts.isEmpty) {
        String? fallbackTag;

        if (categoryId == 'cat_anniversary') {
          fallbackTag = 'anniversary';
        } else if (categoryId == 'cat_birthday') {
          fallbackTag = 'birthday';
        } else if (categoryId == 'cat_gift') {
          fallbackTag = 'gift';
        } else if (categoryId == 'cat_toy') {
          fallbackTag = 'toy';
        } else if (categoryId == 'cat_wedding') {
          fallbackTag = 'wedding';
        } else if (categoryId == 'cat_chocolate') {
          fallbackTag = 'chocolate';
        }
        // Add more mappings if needed

        if (fallbackTag != null) {
          final tagSnapshot =
              await FirebaseFirestore.instance
                  .collection('products')
                  .where('tags', arrayContains: fallbackTag)
                  .get();

          allProducts =
              tagSnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Product.fromJson(data);
              }).toList();
        }
      }

      allProducts.shuffle();
      return allProducts.take(30).toList();
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }
}
