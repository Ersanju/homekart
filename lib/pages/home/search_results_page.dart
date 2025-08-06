import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart'; // <-- add this package in pubspec.yaml

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    final query = widget.query.toLowerCase().trim();

    final snapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final allProducts =
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

    List<Map<String, dynamic>> exactNameMatches = [];
    List<Map<String, dynamic>> fuzzyMatches = [];
    List<Map<String, dynamic>> tagMatches = [];

    for (var product in allProducts) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final tags = (product['tags'] ?? []) as List;

      if (name.contains(query)) {
        exactNameMatches.add(product);
      } else {
        final similarity = StringSimilarity.compareTwoStrings(name, query);
        if (similarity > 0.4) {
          fuzzyMatches.add(product);
        } else if (tags.any(
          (tag) => tag.toString().toLowerCase().contains(query),
        )) {
          tagMatches.add(product);
        }
      }
    }

    // Combine all matches: prioritize name -> fuzzy -> tag
    Set<Map<String, dynamic>> finalResults = {
      ...exactNameMatches,
      ...fuzzyMatches,
      ...tagMatches,
    };

    // Now check if we have less than 10-15 products, fill rest with featured/random
    if (finalResults.length < 15) {
      final needed = 15 - finalResults.length;

      final randomSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .orderBy('popularity', descending: true)
              .limit(needed)
              .get();

      for (var doc in randomSnapshot.docs) {
        final randomProduct = doc.data();
        randomProduct['id'] = doc.id;

        // Avoid duplicates
        if (!finalResults.any((p) => p['id'] == randomProduct['id'])) {
          finalResults.add(randomProduct);
        }
      }
    }

    // Absolute worst case fallback
    if (finalResults.isEmpty) {
      final fallbackSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .limit(15)
              .get();

      finalResults =
          fallbackSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toSet();
    }

    setState(() {
      _results = finalResults.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: "${widget.query}"'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
              ? const Center(child: Text('No matching products found.'))
              : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final product = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        product['imageUrl'] ?? '',
                      ),
                    ),
                    title: Text(product['name'] ?? ''),
                    subtitle: Text("₹${product['price'] ?? 'N/A'}"),
                    onTap: () {
                      // Navigate to product detail
                    },
                  );
                },
              ),
    );
  }
}
