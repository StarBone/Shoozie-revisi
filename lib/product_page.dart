import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shoozie/favorite_page.dart';
import 'package:shoozie/detail_product.dart';
import 'package:shoozie/profile_page.dart';
import 'package:shoozie/input_product.dart';
import 'package:shoozie/seller_product_list.dart';
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
  List brands = [];
  bool isLoading = true;
  String? selectedBrand;
  int? selectedBrandId;
  String? selectedBrandName;
  int? idUser;
  int? idRole;
  List<int> favoriteProductIds = [];

  // Tambahkan variabel untuk menyimpan semua brand
  List<Map<String, dynamic>> allBrands = [];
  Map<String, int> brandNameToId = {};

  List<String> getUniqueBrands() {
    return allBrands.map((b) => b['brand_name'] as String).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchBrands();
    fetchProducts();
    _initUserAndFetch();
  }

  Future<void> _initUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('id_user');
    if (idUser != null) {
      print('User sudah login, id_user: ' + idUser.toString());
      await fetchUserRole(idUser!);
    } else {
      print('Belum ada user login');
    }
    await fetchProducts();
    if (idUser != null) {
      await fetchFavoriteIds();
    }
  }

  Future<void> fetchUserRole(int userId) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/users/$userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          idRole = data['id_role'];
        });
        print('User role: $idRole');
      } else {
        print('Failed to fetch user role: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  Future<void> fetchBrands() async {
    final response = await http.get(Uri.parse('${getBaseUrl()}/brands'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        brands = data;
      });
    } else {
      print('Failed to load brands');
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
    if (idUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan login untuk menambahkan ke favorit')),
      );
      return;
    }
    final url = Uri.parse('${getBaseUrl()}/favorite');
    bool isFav = favoriteProductIds.contains(productId);
    setState(() {
      if (isFav) {
        favoriteProductIds.remove(productId);
      } else {
        favoriteProductIds.add(productId);
      }
    });
    try {
      if (isFav) {
        final response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': productId}),
        );
        if (response.statusCode != 200) {
          await fetchFavoriteIds();
        }
      } else {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': productId}),
        );
        if (response.statusCode != 201) {
          await fetchFavoriteIds();
        }
      }
    } catch (e) {
      await fetchFavoriteIds();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah status favorit')));
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
          if (brand == null) {}
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

  Future<bool> fetchFavoriteStatus(int productId) async {
    if (idUser == null) return false;
    final url = Uri.parse(
      '${getBaseUrl()}/favorite?id_user=$idUser&id_product=$productId',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFavorite'] ?? false;
      }
    } catch (e) {}
    return false;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_outlined, color: Colors.black),
            tooltip: 'My Products',
            onPressed: () async {
              // Use pushReplacement if you want to replace, or push for normal navigation
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          SellerProductList(), // Ganti ke SellerProductList jika sudah ada
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 20.0,
                    ),
                    child: SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedBrandId = null;
                                });
                                fetchProducts();
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(50, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                backgroundColor:
                                    selectedBrandId == null
                                        ? Colors.black
                                        : Colors.grey[200],
                                foregroundColor:
                                    selectedBrandId == null
                                        ? Colors.white
                                        : Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                'All',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          ...brands.map<Widget>((brand) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedBrandId = brand['id_brand'];
                                  });
                                  fetchProducts(brand: brand['id_brand']);
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(50, 32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  backgroundColor:
                                      selectedBrandId == brand['id_brand']
                                          ? Colors.black
                                          : Colors.grey[200],
                                  foregroundColor:
                                      selectedBrandId == brand['id_brand']
                                          ? Colors.white
                                          : Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: Text(
                                  brand['brand_name'],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
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
                          left: 20,
                          right: 20,
                          top: 5,
                          bottom: 80,
                        ),
                        itemCount: products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: kIsWeb ? 0.95 : 0.9,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemBuilder: (context, index) {
                          final product = products[index];
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
                                  await fetchFavoriteIds();
                                  setState(() {});
                                }
                              }
                            },
                            child: Card(
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              color: Colors.white,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if ((product['product_image'] ?? '')
                                            .isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: AspectRatio(
                                              aspectRatio: 16 / 10,
                                              child: Image.memory(
                                                base64Decode(
                                                  product['product_image'],
                                                ),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                  product['product_name'] ??
                                                      '-',
                                                  style: const TextStyle(
                                                    fontFamily: 'Roboto',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (product['product_status'] ??
                                                                        '')
                                                                    .toLowerCase() ==
                                                                'ready'
                                                            ? Colors
                                                                .green
                                                                .shade50
                                                            : Colors
                                                                .red
                                                                .shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          (product['product_status'] ??
                                                                          '')
                                                                      .toLowerCase() ==
                                                                  'ready'
                                                              ? Colors
                                                                  .green
                                                                  .shade200
                                                              : Colors
                                                                  .red
                                                                  .shade200,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${product['product_status'] ?? '-'}',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          (product['product_status'] ??
                                                                          '')
                                                                      .toLowerCase() ==
                                                                  'ready'
                                                              ? Colors
                                                                  .green
                                                                  .shade700
                                                              : Colors
                                                                  .red
                                                                  .shade700,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Iconsax.location,
                                                      size: 8,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        '${product['product_location'] ?? '-'}',
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 8,
                                                          color: Colors.grey,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
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
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        padding: EdgeInsets.all(4),
                                        child: FutureBuilder<bool>(
                                          future: fetchFavoriteStatus(
                                            product['id_product'],
                                          ),
                                          builder: (context, snapshot) {
                                            final isFav =
                                                snapshot.data ?? false;
                                            return GestureDetector(
                                              onTap: () async {
                                                await toggleFavorite(
                                                  product['id_product'],
                                                );
                                                setState(() {});
                                              },
                                              child: Icon(
                                                isFav
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color:
                                                    isFav
                                                        ? Colors.red
                                                        : Colors.grey,
                                                size: 22,
                                              ),
                                            );
                                          },
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
                    ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (idRole == 1) // Only show for admin users
            FloatingActionButton(
              heroTag: "add_product",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InputProduct()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(Iconsax.add, color: Colors.white),
            ),
          if (idRole == 1) const SizedBox(height: 16),
          Container(
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
                          MaterialPageRoute(
                            builder: (context) => FavoritePage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.home_2, color: Colors.black),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                    ),
                    // Removed My Products icon from bottom navigation
                    IconButton(
                      icon: const Icon(Iconsax.user_copy, color: Colors.grey),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
