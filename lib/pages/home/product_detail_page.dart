import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/review.dart';
import '../../utils/app_util.dart';
import '../../utils/cart_provider.dart';
import '../../utils/location_provider.dart';
import '../../utils/wishlist_provider.dart';
import '../../widgets/cake_product_card.dart';
import '../../widgets/delivery_location_section.dart';
import '../cart/cart_page.dart';
import 'chocolate_product_detail_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productDataFuture;
  late Future<List<Product>> _similarProductsFuture;
  late Future<List<Review>> _reviewsFuture;

  int _selectedVariantIndex = 0;
  int _selectedImage = 0;
  Timer? _autoScrollTimer;
  late PageController _pageController;
  int? _expandedTileIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _productDataFuture = _fetchProductData();
    _reviewsFuture = fetchProductReviews(widget.productId);
  }

  Future<Map<String, dynamic>> _fetchProductData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get();

    if (doc.exists) {
      final productData = doc.data()!;
      productData['id'] = doc.id;

      final tags = List<String>.from(productData['tags'] ?? []);
      _similarProductsFuture = fetchSimilarProductsByTags(
        currentProductId: widget.productId,
        tags: tags,
      );

      _startAutoScroll(productData['imageUrls']);
      return productData;
    } else {
      throw Exception("Product not found");
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(dynamic imageUrls) {
    final totalPages = (imageUrls is List) ? imageUrls.length : 1;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_selectedImage + 1) % totalPages;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _selectedImage = nextPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _productDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text("Failed to load product")),
          );
        }

        final productData = snapshot.data!;
        final imageUrls = List<String>.from(productData['imageUrls'] ?? []);
        final variants = List<Map<String, dynamic>>.from(
          productData['extraAttributes']?['cakeAttribute']?['variants'] ?? [],
        );
        final selectedVariant = variants[_selectedVariantIndex];
        final double price = (selectedVariant['price'] as num).toDouble();
        final double? oldPrice =
            selectedVariant['oldPrice'] != null
                ? (selectedVariant['oldPrice'] as num).toDouble()
                : null;

        return Scaffold(
          appBar: AppBar(title: const Text("Product description")),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildImageCarousel(imageUrls),
                  const SizedBox(height: 20),
                  buildProductPriceRow(
                    name: productData['name'] ?? 'Unnamed',
                    price: price,
                    oldPrice: oldPrice,
                  ),
                  const SizedBox(height: 10),
                  buildVariantSelector(
                    variants: variants,
                    selectedIndex: _selectedVariantIndex,
                    onVariantSelected: (index) {
                      setState(() {
                        _selectedVariantIndex = index;
                      });
                    },
                    imageUrls: imageUrls,
                  ),
                  const SizedBox(height: 20),
                  const DeliveryLocationSection(),
                  const SizedBox(height: 20),
                  buildAboutExpandableTilesSection(productData),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Customer Reviews",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<Review>>(
                          future: _reviewsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Text("Failed to load reviews");
                            }
                            return buildReviewSlider(snapshot.data ?? []);
                          },
                        ),
                      ],
                    ),
                  ),
                  buildSimilarProductsSection(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: buildBottomAddToCartButton(
              context,
              productData,
              selectedVariant,
            ),
          ),
        );
      },
    );
  }

  Widget buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imageUrls.length,
              onPageChanged: (index) => setState(() => _selectedImage = index),
              itemBuilder: (context, index) {
                return Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => const Icon(Icons.broken_image, size: 200),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildProductPriceRow({
    required String name,
    required double price,
    double? oldPrice,
  }) {
    final int discountPercent =
        (oldPrice != null && oldPrice > 0)
            ? (((oldPrice - price) / oldPrice) * 100).round()
            : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "₹$price",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (oldPrice != null)
              Text(
                "₹$oldPrice",
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            if (discountPercent > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  "$discountPercent% OFF",
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget buildVariantSelector({
    required List<Map<String, dynamic>> variants,
    required int selectedIndex,
    required void Function(int) onVariantSelected,
    required List<String> imageUrls,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            variants.asMap().entries.map((entry) {
              final index = entry.key;
              final variant = entry.value;
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onVariantSelected(index),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected ? Colors.red.shade50 : Colors.white,
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          variant['image'] ?? imageUrls.first,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${variant['weight']}'),
                      Text(
                        '₹${variant['price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget buildAboutExpandableTilesSection(Map<String, dynamic> product) {
    final List<String> productDescription = List<String>.from(
      product['productDescription'] ?? [],
    );
    final List<String> careInstruction = List<String>.from(
      product['careInstruction'] ?? [],
    );
    final List<String> deliveryInformation = List<String>.from(
      product['deliveryInformation'] ?? [],
    );

    final tiles = [
      {
        "title": "Product Description",
        "icon": Icons.assignment,
        "content": productDescription,
      },
      {
        "title": "Care Instructions",
        "icon": Icons.insert_chart,
        "content": careInstruction,
      },
      {
        "title": "Delivery Information",
        "icon": Icons.local_shipping,
        "content": deliveryInformation,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "About the product",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(tiles.length, (index) {
          final tile = tiles[index];
          final isExpanded = _expandedTileIndex == index;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(tile["icon"] as IconData),
                  title: Text(tile["title"] as String),
                  trailing: Icon(isExpanded ? Icons.remove : Icons.add),
                  onTap:
                      () => setState(() {
                        _expandedTileIndex = isExpanded ? null : index;
                      }),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          (tile["content"] as List<String>).map((text) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                children: [
                                  const Text("• "),
                                  Expanded(child: Text(text)),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget buildReviewSlider(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const Text("No reviews yet.");
    }

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ReviewUserInfo(review: review),
                    const SizedBox(width: 8),
                    Text(
                      "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.comment,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    if (review.occasion.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          review.occasion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    if (review.place.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          border: Border.all(color: Colors.teal),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          review.place,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Review>> fetchProductReviews(String productId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

    if (!doc.exists) return [];

    final data = doc.data();
    if (data == null || data['reviews'] == null) return [];

    final List<dynamic> reviewList = data['reviews'];

    return reviewList
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // sort newest first
  }

  Widget buildBottomAddToCartButton(
    BuildContext context,
    Map<String, dynamic> product,
    Map<String, dynamic> selectedVariant,
  ) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final productId = product['id'];
    final productName = product['name'];
    final imageUrl = (product['imageUrls'] as List).first;
    final price = (selectedVariant['price'] as num).toDouble();
    final sku = selectedVariant['sku'];
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
          final locationProvider = context.read<LocationProvider>();

          // 🛑 Ensure location is checked and available
          if (!locationProvider.hasCheckedAvailability ||
              locationProvider.latitude == null ||
              locationProvider.longitude == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please check delivery availability first."),
              ),
            );
            return;
          }
          final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
          if (!isLoggedIn) return;
          // ✅ Proceed with cart logic
          if (isInCart) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
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
            setState(() {});
          }
        },
        child: Text(
          isInCart ? "Go to Cart" : "Add to Cart",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildSimilarProductsSection() {
    return FutureBuilder<List<Product>>(
      future: _similarProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const CircularProgressIndicator();

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text("No similar products found."),
          );
        }

        final products = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "You May Also Like",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final wishlistProvider = Provider.of<WishlistProvider>(
                    context,
                  );
                  return CakeProductCard(
                    productData: product.toJson(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            return product.productType == 'chocolate_product'
                                ? ChocolateProductDetailPage(
                                  productId: product.id,
                                )
                                : ProductDetailPage(productId: product.id);
                          },
                        ),
                      );
                    },
                    isWishlisted: wishlistProvider.isWishlisted(product.id),
                    onWishlistToggle: () {
                      wishlistProvider.toggleWishlist(product.id);
                      setState(() {}); // To reflect heart icon change
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Product>> fetchSimilarProductsByTags({
    required String currentProductId,
    required List<String> tags,
    int limit = 12,
  }) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('tags', arrayContainsAny: tags)
            .limit(limit)
            .get();

    return snapshot.docs.where((doc) => doc.id != currentProductId).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }
}

class ReviewUserInfo extends StatelessWidget {
  final Review review;

  const ReviewUserInfo({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.green,
          radius: 14,
          child: Icon(Icons.person, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          review.userName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
