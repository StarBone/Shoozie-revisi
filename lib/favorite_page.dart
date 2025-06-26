import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shoozie/detail_product.dart';
import 'package:shoozie/login_page.dart';
import 'package:shoozie/product_page.dart';
import 'package:shoozie/profile_page.dart';
import 'package:shoozie/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<dynamic> favoriteProducts = [];
  List<dynamic> products = [];
  bool isLoading = true;
  int? selectedCategory;
  int? idUser;

  @override
  void initState() {
    super.initState();
    _initUserAndFetchFavorites();
  }

  Future<void> _initUserAndFetchFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('id_user');
    await fetchFavoriteProducts();
  }

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080'; // android
    }
  }

  String getImageAssetPath(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('assets/')) return path;
    return 'assets/' + path;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final bool isLoggedIn = idUser != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Favorite',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Gotham',
            fontSize: 30,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Icon(Icons.favorite, color: Colors.red.shade400, size: 28),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : !isLoggedIn
              ? Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Access Your Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontFamily: 'Gotham',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please log in to view and manage your profile information',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : favoriteProducts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorite products found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 5,
                  bottom: 80,
                ),
                itemCount: favoriteProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: kIsWeb ? 0.95 : 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final product = favoriteProducts[index];
                  String imageAssetPath = getImageAssetPath(
                    product['product_image'],
                  );
                  return GestureDetector(
                    key: ValueKey(product['id_product']),
                    onTap: () async {
                      if (product['id_product'] != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ProductDetailPage(
                                  productId: product['id_product'],
                                ),
                          ),
                        );
                        if (result == true) {
                          fetchFavoriteProducts();
                        }
                      }
                    },
                    child: Card(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      color: Colors.white,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageAssetPath.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 10,
                                      child: Image.asset(
                                        imageAssetPath,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 30,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 4.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          product['product_name'] ?? '-',
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Rp. ${formatter.format(product['product_price'] ?? 0)}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 24,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => ProductDetailPage(
                                                        productId:
                                                            product['id_product'],
                                                      ),
                                                ),
                                              );
                                              if (result == true) {
                                                fetchFavoriteProducts();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor: Colors.black,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 0,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: const Text(
                                              'Detail',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
                  icon: const Icon(Iconsax.heart, color: Colors.black),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FavoritePage()),
                    );
                    if (result == true) {
                      fetchFavoriteProducts();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.home_2_copy, color: Colors.grey),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                    if (result == true) {
                      fetchFavoriteProducts();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.user_copy, color: Colors.grey),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                    if (result == true) {
                      fetchFavoriteProducts();
                    }
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

  // Fetch favorite products for the user from the new /favorites endpoint
  Future<void> fetchFavoriteProducts() async {
    if (idUser == null) {
      setState(() {
        favoriteProducts = [];
        isLoading = false;
      });
      return;
    }
    final url = Uri.parse('${getBaseUrl()}/favorites?id_user=$idUser');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Favorite products: $data'); // Debug log
        setState(() {
          favoriteProducts = data;
          isLoading = false;
        });
      } else {
        setState(() {
          favoriteProducts = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        favoriteProducts = [];
        isLoading = false;
      });
    }
  }

  // Fetch favorite status for a specific product and user
  Future<bool> fetchFavoriteStatus(int productId) async {
    if (idUser == null) return false;
    final url = Uri.parse(
      '${getBaseUrl()}/favorite?id_user=$idUser&id_product=$productId',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] == true;
      }
    } catch (e) {
      // Handle error if needed
    }
    return false;
  }
}
