import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shoozie/favorite_page.dart';
import 'package:shoozie/detail_product.dart';
import 'package:shoozie/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Product extends StatelessWidget {
  const Product({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoozie',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> products = [];
  bool isLoading = true;
  int? selectedBrand;
  int? idUser;
  List<int> favoriteProductIds = [];

  final List<Map<String, dynamic>> brands = [
    {'label': 'All', 'value': null},
    {'label': 'Nike', 'value': 1},
    {'label': 'Adidas', 'value': 2},
    {'label': 'Puma', 'value': 3},
  ];

  @override
  void initState() {
    super.initState();
    _initUserAndFetch();
  }

  Future<void> _initUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('id_user');
    if (idUser != null) {
      print('User sudah login, id_user: ' + idUser.toString());
    } else {
      print('Belum ada user login');
    }
    await fetchProducts();
    if (idUser != null) {
      await fetchFavoriteIds();
    }
  }

  Future<void> fetchFavoriteIds() async {
    if (idUser == null) return;
    final url = Uri.parse('${getBaseUrl()}/favorit/$idUser');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            favoriteProductIds =
                data.map<int>((item) => item['id_product'] as int).toList();
          });
        }
      }
    } catch (e) {}
  }

  Future<void> toggleFavorite(int productId) async {
    if (idUser == null) return;
    final url = Uri.parse('${getBaseUrl()}/favorite');
    bool isFav = favoriteProductIds.contains(productId);
    try {
      if (isFav) {
        await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': productId}),
        );
      } else {
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': productId}),
        );
      }
      await fetchFavoriteIds();
    } catch (e) {
      return;
    }
  }

  Future<void> fetchProducts({int? brand}) async {
    setState(() {
      isLoading = true;
    });
    String urlStr = '${getBaseUrl()}/product';
    if (brand != null) {
      urlStr += '?id_brand=$brand';
    }
    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080'; // android
    }
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Cek jika path sudah mengandung "/assets/", jika tidak tambahkan
    if (path.contains('/assets/')) {
      return getBaseUrl() + path;
    }
    return getBaseUrl() + '/assets/' + path;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Shoozie',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Gotham',
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Brand Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 33,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              brands
                                  .map(
                                    (brand) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedBrand = brand['value'];
                                          });
                                          fetchProducts(brand: brand['value']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(60, 100),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                          ),
                                          backgroundColor:
                                              selectedBrand == brand['value']
                                                  ? Colors.black
                                                  : Colors.grey[200],
                                          foregroundColor:
                                              selectedBrand == brand['value']
                                                  ? Colors.white
                                                  : Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          brand['label'],
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                  if (products.isEmpty && !isLoading)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No products found',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  else if (!isLoading)
                    // Product Cards
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 30,
                          top: 5,
                          bottom: 80,
                        ),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: kIsWeb ? 0.8 : 0.73,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isFav = favoriteProductIds.contains(
                            product['id_product'],
                          );
                          String imageAssetPath =
                              product['product_image'] ?? '';
                          return GestureDetector(
                            onTap: () async {
                              if (product['id_product'] != null) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ProductDetailPage(
                                          productId: product['id_product'],
                                        ),
                                  ),
                                );
                                await fetchProducts(brand: selectedBrand);
                                await fetchFavoriteIds();
                                setState(() {});
                              }
                            },
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey),
                              ),
                              color: Colors.white,
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (imageAssetPath.isNotEmpty)
                                        AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: Image.asset(
                                            imageAssetPath,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.image,
                                                      size: 100,
                                                    ),
                                          ),
                                        )
                                      else
                                        Icon(Icons.image, size: 100),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['product_name'] ?? '-',
                                              style: const TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rp. ${formatter.format(product['product_price'] ?? 0)}',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Lokasi: ${product['product_location'] ?? '-'}',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Status: ${product['product_status'] ?? '-'}',
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () async {
                                        await toggleFavorite(
                                          product['id_product'],
                                        );
                                      },
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFav ? Colors.red : Colors.grey,
                                        size: 25,
                                      ),
                                    ),
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
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 150 : 120),
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Iconsax.heart_copy, color: Colors.grey),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FavoritePage()),
                    );
                    fetchProducts(brand: selectedBrand);
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.home_2, color: Colors.black),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                    fetchProducts(brand: selectedBrand);
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.user_copy, color: Colors.grey),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                    fetchProducts(brand: selectedBrand);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
