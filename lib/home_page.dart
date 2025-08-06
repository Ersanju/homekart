import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homekart/pages/account/edit_profile_page.dart';
import 'package:homekart/pages/authentication/login_page.dart';
import 'package:homekart/pages/home/chocolate_product_detail_page.dart';
import 'package:homekart/pages/home/product_detail_page.dart';
import 'package:homekart/pages/home/products_by_category_grid_page.dart';
import 'package:homekart/pages/home/search_results_page.dart';
import 'package:homekart/utils/app_auth_provider.dart';
import 'package:homekart/utils/app_util.dart';
import 'package:homekart/utils/wishlist_provider.dart';
import 'package:homekart/widgets/cake_product_card.dart';
import 'package:homekart/widgets/chocolate_product_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/product.dart';
import 'models/product_category.dart';

// Helper function for isolate-based JSON decoding
Future<List<ProductCategory>> _decodeCategories(List<String> cachedCategories) async {
  return compute((data) {
    return data
        .map((e) => ProductCategory.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }, cachedCategories);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool hasInternet = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool isHomeLoading = true;
  List<ProductCategory> categories = [];
  List<String> bannerImages = [];
  List<Map<String, dynamic>> featuredProducts = [];
  List<Map<String, dynamic>> newArrivals = [];
  List<Map<String, dynamic>> chocolates = [];
  List<Map<String, dynamic>> youMayAlsoLikeProducts = [];
  List<Map<String, dynamic>> appReviews = [];
  String _locationText = 'Fetching location...';
  String _pinCode = '';
  Timer? _timer;
  bool isLoadingBanners = false;
  Map<String, int> cartQuantities = {};
  Map<String, int> variantQuantities = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isDataLoaded = false; // Track if initial data load is complete
  bool _isLocationFetched = false; // Track if actual location is fetched

  @override
  void initState() {
    super.initState();
    _startConnectivityListener();
    _loadCachedData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && bannerImages.isNotEmpty && !isHomeLoading) {
        final nextPage = (_pageController.page!.round() + 1) % bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final realInternet = await _hasRealInternet();
      if (!mounted) return;
      setState(() {
        hasInternet = realInternet;
      });
      if (realInternet && !_isDataLoaded) {
        await _loadAllData();
      }
    });
  }

  Future<void> _saveToCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == 'categories' && data is List<ProductCategory>) {
      await prefs.setStringList(key, data.map((e) => jsonEncode(e.toJson())).toList());
    } else if (key == 'banners' && data is List<String>) {
      await prefs.setStringList(key, data);
    } else if (['featuredProducts', 'chocolates', 'newArrivals', 'youMayAlsoLikeProducts', 'appReviews'].contains(key)) {
      await prefs.setStringList(key, data.map((e) => jsonEncode(e)).toList());
    } else if (key == 'locationText' && data is String) {
      await prefs.setString(key, data);
    } else if (key == 'pinCode' && data is String) {
      await prefs.setString(key, data);
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCategories = prefs.getStringList('categories') ?? [];
    final cachedBanners = prefs.getStringList('banners') ?? [];
    final cachedFeatured = prefs.getStringList('featuredProducts') ?? [];
    final cachedChocolates = prefs.getStringList('chocolates') ?? [];
    final cachedNewArrivals = prefs.getStringList('newArrivals') ?? [];
    final cachedYouMayAlsoLike = prefs.getStringList('youMayAlsoLikeProducts') ?? [];
    final cachedAppReviews = prefs.getStringList('appReviews') ?? [];
    final cachedLocationText = prefs.getString('locationText') ?? 'Fetching location...';
    final cachedPinCode = prefs.getString('pinCode') ?? '';

    List<ProductCategory> loadedCategories = [];
    try {
      loadedCategories = await _decodeCategories(cachedCategories);
    } catch (e) {
      debugPrint("Error loading cached categories: $e");
    }

    if (!mounted) return;
    setState(() {
      categories = loadedCategories;
      bannerImages = cachedBanners;
      featuredProducts = cachedFeatured.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      chocolates = cachedChocolates.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      newArrivals = cachedNewArrivals.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      youMayAlsoLikeProducts = cachedYouMayAlsoLike.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      appReviews = cachedAppReviews.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      _locationText = cachedLocationText;
      _pinCode = cachedPinCode;
      _isLocationFetched = cachedLocationText != 'Fetching location...' &&
          cachedLocationText != 'Location services disabled' &&
          cachedLocationText != 'Permission denied' &&
          cachedLocationText != 'Permission permanently denied' &&
          cachedLocationText != 'Error fetching location' &&
          cachedLocationText != 'Location not found';
      isHomeLoading = loadedCategories.isEmpty && cachedBanners.isEmpty;
      isLoadingBanners = cachedBanners.isEmpty;
      _isDataLoaded = !isHomeLoading;
    });

    if (categories.isNotEmpty || bannerImages.isNotEmpty) {
      unawaited(_preCacheHomeImages());
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted || _isDataLoaded) return;
    setState(() => isHomeLoading = true);

    try {
      await Future.wait([
        _fetchAllContent(),
        _fetchLocation(),
      ]);
      if (!mounted) return;
      setState(() {
        isHomeLoading = false;
        _isDataLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading all data: $e");
      if (!mounted) return;
      setState(() => isHomeLoading = false);
    }
  }

  Future<void> _fetchAllContent() async {
    try {
      final categoryQuery = FirebaseFirestore.instance.collection('categories');
      final nullSnapshotFuture = categoryQuery.where('active', isEqualTo: true).where('categoryId', isNull: true).limit(10).get();
      final emptySnapshotFuture = categoryQuery.where('active', isEqualTo: true).where('categoryId', isEqualTo: '').limit(10).get();
      final bannerFuture = FirebaseFirestore.instance.collection('banners').where('active', isEqualTo: true).limit(5).get();
      final featuredFuture = FirebaseFirestore.instance.collection('products').where('tags', arrayContains: 'featured').limit(5).get();
      final chocolatesFuture = FirebaseFirestore.instance.collection('products').where('categoryId', isEqualTo: 'cat_chocolate').limit(5).get();
      final newArrivalsFuture = FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).limit(5).get();
      final youMayAlsoLikeFuture = FirebaseFirestore.instance.collection('products').where('tags', arrayContainsAny: ['recommended', 'trending']).limit(5).get();
      final appReviewsFuture = FirebaseFirestore.instance.collection('app_reviews').orderBy('createdAt', descending: true).limit(3).get();

      final results = await Future.wait([
        nullSnapshotFuture,
        emptySnapshotFuture,
        bannerFuture,
        featuredFuture,
        chocolatesFuture,
        newArrivalsFuture,
        youMayAlsoLikeFuture,
        appReviewsFuture,
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs];
      final seen = <String>{};
      final fetchedCategories = allDocs.where((doc) => seen.add(doc.id)).map((doc) => ProductCategory.fromMap(doc.id, doc.data())).toList();
      final fetchedBanners = results[2].docs.map((d) => d['imageUrl'] as String).toList();
      final fetchedFeatured = results[3].docs.map((d) => d.data()).toList();
      final fetchedChocolates = results[4].docs.map((d) => d.data()).toList();
      final fetchedNewArrivals = results[5].docs.map((d) => d.data()).toList();
      final fetchedYouMayAlsoLike = results[6].docs.map((d) => d.data()).toList();
      final fetchedAppReviews = results[7].docs.map((d) => d.data()).toList();

      if (!mounted) return;
      setState(() {
        categories = fetchedCategories;
        bannerImages = fetchedBanners;
        featuredProducts = fetchedFeatured;
        chocolates = fetchedChocolates;
        newArrivals = fetchedNewArrivals;
        youMayAlsoLikeProducts = fetchedYouMayAlsoLike;
        appReviews = fetchedAppReviews;
        isLoadingBanners = false;
      });

      await Future.wait([
        _saveToCache('categories', fetchedCategories),
        _saveToCache('banners', fetchedBanners),
        _saveToCache('featuredProducts', fetchedFeatured),
        _saveToCache('chocolates', fetchedChocolates),
        _saveToCache('newArrivals', fetchedNewArrivals),
        _saveToCache('youMayAlsoLikeProducts', fetchedYouMayAlsoLike),
        _saveToCache('appReviews', fetchedAppReviews),
      ]);

      unawaited(_preCacheHomeImages());
    } catch (e) {
      debugPrint("Error fetching content: $e");
    }
  }

  Future<void> _preCacheHomeImages() async {
    if (!mounted) return;
    final allImageUrls = [
      ...bannerImages,
      ...featuredProducts.map((p) => p['imageUrl'] as String? ?? ''),
      ...chocolates.map((p) => p['imageUrl'] as String? ?? ''),
      ...newArrivals.map((p) => p['imageUrl'] as String? ?? ''),
      ...youMayAlsoLikeProducts.map((p) => p['imageUrl'] as String? ?? ''),
    ].where((url) => url.isNotEmpty).toSet().toList();

    const batchSize = 2; // Reduced batch size for better performance
    for (var i = 0; i < allImageUrls.length; i += batchSize) {
      final batch = allImageUrls.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((url) async {
        try {
          await compute((imageUrl) async {
            await precacheImage(CachedNetworkImageProvider(imageUrl), context);
          }, url);
        } catch (e) {
          debugPrint("Error precaching image $url: $e");
        }
      }));
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _fetchLocation({bool fromTap = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _locationText = 'Location services disabled';
        _pinCode = '';
        _isLocationFetched = false;
      });
      await _saveToCache('locationText', _locationText);
      await _saveToCache('pinCode', _pinCode);
      if (fromTap) {
        await _showLocationPermissionDialog('Please enable location services in your device settings.');
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || fromTap) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _locationText = 'Permission denied';
          _pinCode = '';
          _isLocationFetched = false;
        });
        await _saveToCache('locationText', _locationText);
        await _saveToCache('pinCode', _pinCode);
        if (fromTap) {
          await _showLocationPermissionDialog('Location permission is required to provide accurate delivery information.');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _locationText = 'Permission permanently denied';
        _pinCode = '';
        _isLocationFetched = false;
      });
      await _saveToCache('locationText', _locationText);
      await _saveToCache('pinCode', _pinCode);
      if (fromTap) {
        await _showLocationPermissionDialog(
            'Location permission is permanently denied. Please enable it in your app settings.',
            openSettings: true);
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          _locationText = '${place.locality}, ${place.administrativeArea}';
          _pinCode = place.postalCode ?? '';
          _isLocationFetched = true;
        });
        await _saveToCache('locationText', _locationText);
        await _saveToCache('pinCode', _pinCode);
      } else {
        if (!mounted) return;
        setState(() {
          _locationText = 'Location not found';
          _pinCode = '';
          _isLocationFetched = false;
        });
        await _saveToCache('locationText', _locationText);
        await _saveToCache('pinCode', _pinCode);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationText = 'Error fetching location';
        _pinCode = '';
        _isLocationFetched = false;
      });
      await _saveToCache('locationText', _locationText);
      await _saveToCache('pinCode', _pinCode);
      if (fromTap) {
        await _showLocationPermissionDialog('Failed to fetch location. Please try again.');
      }
    }
  }

  Future<void> _showLocationPermissionDialog(String message, {bool openSettings = false}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (openSettings) {
                await Geolocator.openAppSettings();
              } else {
                await _fetchLocation(fromTap: true);
              }
            },
            child: Text(openSettings ? 'Open Settings' : 'Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _currentIndex == 0 ? buildAppBar() : null,
        body: hasInternet
            ? _pages[_currentIndex]
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage('assets/icon/no_internet.gif'),
                width: 400,
                height: 450,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAllData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: buildBottomNavigationBar(),
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final userData = auth.userData;
    final isLoggedIn = user != null;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: GestureDetector(
        onTap: _isLocationFetched ? null : () => _fetchLocation(fromTap: true),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.black),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationText,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: _isLocationFetched ? TextDecoration.none : TextDecoration.underline,
                  ),
                ),
                Text(
                  _pinCode,
                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (!isLoggedIn)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text("Login / Signup"),
          )
        else
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: userData?['profileImageUrl']?.isNotEmpty == true
                            ? CachedNetworkImageProvider(userData!['profileImageUrl'])
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: userData?['profileImageUrl']?.isEmpty != false ? const Icon(Icons.person, size: 16) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData?['name']?.split(' ').first ?? "User",
                        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildHomeContent() {
    if (isHomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 5)),
        SliverToBoxAdapter(child: buildSearchBar(context, _searchController, () => _handleSearch(context))),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: buildCategorySection()),
        SliverToBoxAdapter(child: buildBannerSlider()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: featuredOffersSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: chocolateBarSection(chocolates)),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: newArrivalsSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: youMayAlsoLikeSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: appReviewsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: brandingSection()),
      ],
    );
  }

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
      ],
    );
  }

  List<Widget> get _pages => [
    buildHomeContent(),
    const Text("CategoryPage"),
    const Text("CartPage"),
    const Text("AccountPage"),
  ];

  void _handleSearch(BuildContext context) {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least 3 characters")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultsPage(query: query)),
    );
  }

  Widget buildSearchBar(BuildContext context, TextEditingController controller, VoidCallback onSearch) {
    const hints = [
      "   Search for cakes...",
      "   Search for gifts...",
      "   Search for flowers...",
      "   Search for toys...",
      "   Search for celebration items...",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, child) {
          final isTyping = controller.text.isNotEmpty;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(fontSize: 16),
                textAlignVertical: TextAlignVertical.center, // Ensure text is vertically centered
                decoration: InputDecoration(
                  hintText: "", // Empty to allow AnimatedTextKit to handle hints
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22), // Increased vertical padding
                  alignLabelWithHint: true, // Align hint with input text vertically
                  suffixIcon: isTyping
                      ? Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 2, bottom: 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.black),
                        onPressed: onSearch,
                      ),
                    ),
                  )
                      : null,
                  prefixIcon: isTyping ? null : const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (!isTyping)
                Positioned.fill(
                  left: 48, // Matches prefixIcon width
                  top: 0, // Explicitly align to center vertically
                  child: Align(
                    alignment: Alignment.centerLeft, // Ensure vertical centering
                    child: IgnorePointer(
                      child: AnimatedTextKit(
                        animatedTexts: hints
                            .map((text) => TyperAnimatedText(
                          text,
                          textStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.0, // Match TextField's text style
                          ),
                          speed: const Duration(milliseconds: 60),
                        ))
                            .toList(),
                        repeatForever: true,
                        pause: const Duration(milliseconds: 1500),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildCategorySection() {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: _buildCategoryPairs(categories),
      ),
    );
  }

  List<Widget> _buildCategoryPairs(List<ProductCategory> categories) {
    final pairs = <Widget>[];
    final half = (categories.length / 2).ceil();

    for (var i = 0; i < half; i++) {
      final top = categories[i];
      final bottom = (i + half < categories.length) ? categories[i + half] : null;

      pairs.add(
        Container(
          width: 90,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildCategoryItem(top),
              const SizedBox(height: 12),
              if (bottom != null) buildCategoryItem(bottom),
            ],
          ),
        ),
      );
    }
    return pairs;
  }

  Widget buildCategoryItem(ProductCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductsByCategoryGridPage(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Hero(
            tag: category.id,
            child: CircleAvatar(
              radius: 33,
              backgroundImage: CachedNetworkImageProvider(category.imageUrl),
              backgroundColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget buildBannerSlider() {
    if (isLoadingBanners) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (bannerImages.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text("No banners available")));
    }
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: bannerImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: CachedNetworkImageProvider(bannerImages[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget chocolateBarSection(List<Map<String, dynamic>> chocolates) {
    if (chocolates.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Shop For Chocolate Bars",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: chocolates.length,
            itemBuilder: (context, index) {
              final productData = chocolates[index];
              final chocolateAttr = productData['extraAttributes']?['chocolateAttribute'];
              final variant = (chocolateAttr?['variants'] as List?)?.first;
              if (variant == null) return const SizedBox.shrink();

              final product = Product.fromJson(productData);
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 4,
                  right: index == chocolates.length - 1 ? 16 : 8,
                ),
                child: ChocolateProductCard(
                  productData: productData,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChocolateProductDetailPage(productId: product.id),
                    ),
                  ),
                  onVariantTap: () => ChocolateProductCard.showVariantsBottomSheet(context, product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget featuredOffersSection(BuildContext context) {
    if (featuredProducts.isEmpty) return const SizedBox.shrink();
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("🎉 Featured Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredProducts.length,
            padding: const EdgeInsets.only(left: 16),
            itemBuilder: (context, index) {
              final productData = featuredProducts[index];
              final productId = productData['id'];
              return CakeProductCard(
                productData: productData,
                isWishlisted: wishlistProvider.isWishlisted(productId),
                onWishlistToggle: () async {
                  final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
                  if (!isLoggedIn) return;
                  wishlistProvider.toggleWishlist(productId);
                },
                onTap: () {
                  final route = productId.startsWith('sub_cat_cake')
                      ? ProductDetailPage(productId: productId)
                      : ChocolateProductDetailPage(productId: productId);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => route));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget newArrivalsSection(BuildContext context) {
    if (newArrivals.isEmpty) return const SizedBox.shrink();
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("🆕 New Arrivals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final productData = newArrivals[index];
              final productId = productData['id'];
              final categoryId = productData['categoryId'];
              final Widget card = categoryId == 'cat_chocolate'
                  ? ChocolateProductCard(
                productData: productData,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChocolateProductDetailPage(productId: productId),
                  ),
                ),
                onVariantTap: () {
                  final product = Product.fromJson(productData);
                  ChocolateProductCard.showVariantsBottomSheet(context, product);
                },
              )
                  : CakeProductCard(
                productData: productData,
                isWishlisted: wishlistProvider.isWishlisted(productId),
                onWishlistToggle: () async {
                  final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
                  if (!isLoggedIn) return;
                  wishlistProvider.toggleWishlist(productId);
                },
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(productId: productId),
                  ),
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(width: 120, child: card),
              );
            },
            itemCount: newArrivals.length,
          ),
        ),
      ],
    );
  }

  Widget youMayAlsoLikeSection(BuildContext context) {
    if (youMayAlsoLikeProducts.isEmpty) return const SizedBox.shrink();
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("❤️ You May Also Like", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: youMayAlsoLikeProducts.length,
            itemBuilder: (context, index) {
              final productData = youMayAlsoLikeProducts[index];
              final productId = productData['id'];
              return CakeProductCard(
                productData: productData,
                isWishlisted: wishlistProvider.isWishlisted(productId),
                onWishlistToggle: () async {
                  final isLoggedIn = await AppUtil.ensureLoggedInGlobal(context);
                  if (!isLoggedIn) return;
                  wishlistProvider.toggleWishlist(productId);
                },
                onTap: () {
                  final route = productId.startsWith('sub_cat_cake')
                      ? ProductDetailPage(productId: productId)
                      : ChocolateProductDetailPage(productId: productId);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => route));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget appReviewsSection() {
    if (appReviews.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text("⭐ What Our Customers Say", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            itemCount: appReviews.length,
            itemBuilder: (context, index) {
              final data = appReviews[index];
              final userName = data['userName'] ?? 'Anonymous';
              final city = data['city'] ?? '';
              final message = data['message'] ?? '';
              final rating = (data['rating'] ?? 5).toDouble();
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                            (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      "- $userName, $city",
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget brandingSection() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🌸 Why HomeKart?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          BrandingTile(
            emoji: "🎁",
            title: "Curated Gifting",
            subtitle: "Handpicked items for every celebration.",
          ),
          BrandingTile(
            emoji: "🚚",
            title: "On-Time Delivery",
            subtitle: "Timely, safe delivery you can rely on.",
          ),
          BrandingTile(
            emoji: "🧁",
            title: "Premium Quality",
            subtitle: "Fresh, delicious and beautifully made.",
          ),
          BrandingTile(
            emoji: "📞",
            title: "24x7 Support",
            subtitle: "Always here to help, anytime.",
          ),
        ],
      ),
    );
  }
}

class BrandingTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const BrandingTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}