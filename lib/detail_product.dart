import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? product;
  bool isLoading = true;
  bool isFavorite = false;
  int? idUser;
  bool favoriteChanged = false;

  @override
  void initState() {
    super.initState();
    _initUserAndProduct();
  }

  Future<void> _initUserAndProduct() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('id_user');
    await fetchProductDetail();
    if (idUser != null) {
      await fetchFavoriteStatus();
    }
  }

  Future<void> fetchProductDetail() async {
    final url = Uri.parse('${getBaseUrl()}/product/${widget.productId}');
    try {
      final response = await http.get(url);
      debugPrint('Response status: \\${response.statusCode}');
      debugPrint('Response body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          product = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetchProductDetail: \\${e.toString()}');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchFavoriteStatus() async {
    if (idUser == null) return;
    final url = Uri.parse('${getBaseUrl()}/favorite/$idUser');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            isFavorite = data.any(
              (item) => item['id_product'] == widget.productId,
            );
          });
        }
      }
    } catch (e) {}
  }

  Future<void> toggleFavorite() async {
    if (idUser == null || product == null) return;
    final url = Uri.parse('${getBaseUrl()}/favorite');
    try {
      if (isFavorite) {
        await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': widget.productId}),
        );
        setState(() {
          isFavorite = false;
        });
        favoriteChanged = true;
      } else {
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': widget.productId}),
        );
        setState(() {
          isFavorite = true;
        });
        favoriteChanged = true;
      }
    } catch (e) {}
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
    // Jika path tidak mengandung '/assets/', asumsikan gambar di folder 'assets' backend
    if (!path.contains('/assets/')) {
      return getBaseUrl() + '/assets/' + path;
    }
    return getBaseUrl() + path;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, favoriteChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, favoriteChanged);
            },
            splashRadius: 24,
          ),
          title: const Text(
            'Shoozie',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Gotham',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: kIsWeb ? 25 : 30,
                ),
                onPressed: () async {
                  await toggleFavorite();
                },
                splashRadius: 24,
              ),
            ),
          ],
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        backgroundColor: Colors.white,
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : (product == null || product!.isEmpty)
                ? Center(child: Text('Product not found'))
                : Column(
                  children: [
                    // Product Image
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Builder(
                        builder: (context) {
                          final imagePath = product!['product_image'] ?? '';
                          if (imagePath != null && imagePath.isNotEmpty) {
                            return Image.asset(
                              imagePath,
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Icon(Icons.image, size: 200),
                            );
                          } else {
                            return Icon(Icons.image, size: 200);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product!['product_name'] ?? '-',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: kIsWeb ? 16 : 22,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rp. ${product!['product_price'] ?? '-'}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: kIsWeb ? 14 : 20,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Divider(color: Colors.black),
                                Text(
                                  'Deskripsi',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: kIsWeb ? 12 : 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  product!['description'] ?? '-',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: kIsWeb ? 12 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                  ],
                ),
      ),
    );
  }
}
