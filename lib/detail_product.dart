import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<int> favoriteProductIds = [];

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
    } catch (e) {
      setState(() {
        favoriteProductIds = [];
      });
    }
  }

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
      await fetchFavoriteIds();
    }
  }

  Future<void> fetchProductDetail() async {
    final url = Uri.parse('${getBaseUrl()}/product/${widget.productId}');
    try {
      final response = await http.get(url);
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
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> toggleFavorite() async {
    if (idUser == null || product == null) return;
    final url = Uri.parse('${getBaseUrl()}/favorite');
    final productId = widget.productId;
    final isFav = favoriteProductIds.contains(productId);
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
      setState(() {});
    } catch (e) {}
  }

  void openWhatsApp(String phone) async {
    if (phone.isEmpty || phone == '-') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nomor WhatsApp tidak tersedia')));
      return;
    }
    String phoneNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '62' + phoneNumber.substring(1);
    }
    final url = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
    }
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

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Jika path tidak mengandung '/assets/', asumsikan gambar di folder 'assets' backend
    if (!path.contains('/assets/')) {
      return getBaseUrl() + '/assets/' + path;
    }
    return getBaseUrl() + path;
  }

  String formatRupiah(dynamic price) {
    if (price == null) return '-';
    try {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp. ',
        decimalDigits: 0,
      );
      return formatter.format(int.tryParse(price.toString()) ?? 0);
    } catch (e) {
      return price.toString();
    }
  }

  String _formatTanggal(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';
    try {
      final date = DateTime.parse(dateTimeStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
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
              fontSize: 30,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  favoriteProductIds.contains(widget.productId)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      favoriteProductIds.contains(widget.productId)
                          ? Colors.red
                          : Colors.grey,
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
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Product Image
                      Builder(
                        builder: (context) {
                          final imagePath = getImageAssetPath(
                            product!['product_image'],
                          );
                          if (imagePath.isNotEmpty) {
                            return Image.asset(
                              imagePath,
                              height: 400,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Icon(Icons.image, size: 200),
                            );
                          } else {
                            return Icon(Icons.image, size: 200);
                          }
                        },
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
                                    formatRupiah(product!['product_price']),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: kIsWeb ? 14 : 20,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    product!['product_name'] ?? '-',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: kIsWeb ? 16 : 22,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.location,
                                            size: 12,
                                            color: Colors.grey[700],
                                          ),
                                          SizedBox(width: 1),
                                          Text(
                                            product!['product_location'] ?? '-',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: kIsWeb ? 11 : 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatTanggal(product!['created_at']),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: kIsWeb ? 11 : 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Detail',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: kIsWeb ? 12 : 16,
                                    ),
                                  ),
                                  Divider(color: Colors.black),
                                  Text(
                                    'Description :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
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
                                  SizedBox(height: 12),
                                  Divider(color: Colors.black),
                                  Text(
                                    'Status Product :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: kIsWeb ? 12 : 16,
                                    ),
                                  ),
                                  Text(
                                    product!['product_status'] ?? '-',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: kIsWeb ? 12 : 16,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Divider(color: Colors.black),
                                  Text(
                                    'Nomor Telepon (Whatssapp) :',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: kIsWeb ? 12 : 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        product!['seller_contact'] ?? '-',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: kIsWeb ? 12 : 16,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          openWhatsApp(
                                            product!['seller_contact'] ?? '',
                                          );
                                        },
                                        child: Icon(Iconsax.whatsapp, size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
    );
  }
}
