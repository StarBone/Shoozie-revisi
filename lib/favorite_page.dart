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

  Future<void> fetchFavoriteProducts() async {
    if (idUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final url = Uri.parse('${getBaseUrl()}/favorit/$idUser');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          favoriteProducts = data;
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

  Future<void> fetchProducts({int? category}) async {
    setState(() {
      isLoading = true;
    });
    String urlStr = '${getBaseUrl()}/produk';
    if (category != null) {
      urlStr += '?id_kategori=$category';
    }
    final url = Uri.parse(urlStr);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ambil varian untuk setiap produk
        List<dynamic> productsWithVarian = [];
        for (final product in data) {
          final varianUrl = Uri.parse(
            '${getBaseUrl()}/produk/${product['id_product']}/varian',
          );
          final varianResp = await http.get(varianUrl);
          if (varianResp.statusCode == 200) {
            final varianList = jsonDecode(varianResp.body);
            product['varian_produk'] = varianList;
          } else {
            product['varian_produk'] = [];
          }
          productsWithVarian.add(product);
        }
        setState(() {
          products = productsWithVarian;
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

  Future<int> _getCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');
    if (idUser == null) return 0;
    try {
      final url = Uri.parse("${getBaseUrl()}/keranjang/$idUser");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          int total = 0;
          for (final item in data) {
            total += (item['jumlah'] ?? 1) as int;
          }
          return total;
        }
      }
    } catch (e) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final bool isLoggedIn = idUser != null;
    return Scaffold(
      backgroundColor: Colors.white,
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
            child: Stack(
              children: [
                FutureBuilder<int>(
                  future: _getCartCount(),
                  builder: (context, snapshot) {
                    int count = snapshot.data ?? 0;
                    if (count == 0) return SizedBox.shrink();
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : !isLoggedIn
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('If you want to add Favorite'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 70),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('or'),
                    const SizedBox(height: 3),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 70),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              )
              : favoriteProducts.isEmpty
              ? const Center(
                child: Text(
                  'No favorite products found',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.only(left: 30, right: 30, top: 5),
                itemCount: favoriteProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: kIsWeb ? 0.9 : 0.73,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),

                itemBuilder: (context, index) {
                  final product = favoriteProducts[index];
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigasi ke detail produk jika diinginkan
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SizedBox(height: 30),
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 2,
                                    child:
                                        (product['gambar_produk'] != null &&
                                                product['gambar_produk']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? Image.network(
                                              product['gambar_produk']
                                                  .toString(),
                                              fit: BoxFit.cover,
                                            )
                                            : Icon(Icons.image, size: 100),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rp. ${formatter.format(product['harga_product'])}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  product['nama_product'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w100,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 25,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ProductDetailPage(
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      'Detail',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.pinkAccent,
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
}
