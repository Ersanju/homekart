import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../home/product_detail_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> categories = [];
  String? selectedCategoryId;

  Map<String, List<Map<String, dynamic>>> subcategoryCache = {};
  Map<String, List<Map<String, dynamic>>> productCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('categories')
            .where('categoryId', isEqualTo: '') // top-level
            .where('active', isEqualTo: true)
            .orderBy('priority')
            .get();

    final data =
        snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data()};
        }).toList();
    setState(() {
      categories = data;
      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first['id'];
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchSubcategories(
    String categoryId,
  ) async {
    if (subcategoryCache.containsKey(categoryId)) {
      return subcategoryCache[categoryId]!;
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection('categories')
            .where('categoryId', isEqualTo: categoryId)
            // .where('active', isEqualTo: true)
            // .orderBy('priority')
            .get();

    final data = snapshot.docs.map((doc) => doc.data()).toList();
    subcategoryCache[categoryId] = data;
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchProducts(String subCategoryId) async {
    if (productCache.containsKey(subCategoryId)) {
      return productCache[subCategoryId]!;
    }

    final snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('subCategoryIds', arrayContains: subCategoryId)
            // .where('available', isEqualTo: true)
            .get();

    final data = snapshot.docs.map((doc) => doc.data()).toList();
    productCache[subCategoryId] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('All Categories'), centerTitle: true),
      body: Row(
        children: [
          // Left: Vertical Category List
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6), // Light purple or your brand tone
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 0),
                ),
              ],
              border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final category = categories[index];
                final isSelected = category['id'] == selectedCategoryId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategoryId = category['id'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: CachedNetworkImageProvider(
                            category['imageUrl'],
                          ),
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: isSelected ? Colors.purple : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Right: Subcategories & Products
          Expanded(
            child:
                selectedCategoryId == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchSubcategories(selectedCategoryId!),
                      builder: (_, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final subcategories = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: subcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory = subcategories[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    subcategory['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: fetchProducts(subcategory['id']),
                                  builder: (_, productSnap) {
                                    if (!productSnap.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final products = productSnap.data!;
                                    if (products.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text("No products available"),
                                      );
                                    }

                                    // Group products into vertical 3-row layout
                                    final rowCount = 3;
                                    final columns = List.generate(
                                      (products.length / rowCount).ceil(),
                                      (i) =>
                                          products
                                              .skip(i * rowCount)
                                              .take(rowCount)
                                              .toList(),
                                    );

                                    return SizedBox(
                                      height: 400,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children:
                                            columns.map((columnProducts) {
                                              return Container(
                                                width: 90,
                                                margin: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                child: Column(
                                                  children:
                                                      columnProducts.map((
                                                        product,
                                                      ) {
                                                        final imageUrl =
                                                            (product['imageUrls']
                                                                            as List?)
                                                                        ?.isNotEmpty ==
                                                                    true
                                                                ? product['imageUrls'][0]
                                                                : '';
                                                        final name =
                                                            product['name'] ??
                                                            '';
                                                        final price =
                                                            product['extraAttributes']?['cakeAttribute']?['variants']?[0]?['price'] ??
                                                            '';

                                                        return GestureDetector(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => ProductDetailPage(
                                                                      productId:
                                                                          product['id'],
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            width: 90,
                                                            margin:
                                                                const EdgeInsets.only(
                                                                  right: 1,
                                                                  bottom: 8,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  1,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color:
                                                                      Colors
                                                                          .black12,
                                                                  blurRadius: 4,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        2,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                  child: Image.network(
                                                                    imageUrl,
                                                                    height: 80,
                                                                    width:
                                                                        double
                                                                            .infinity,
                                                                    fit:
                                                                        BoxFit
                                                                            .cover,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  name,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                Text(
                                                                  '₹$price',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        Colors
                                                                            .green,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
