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
  int? idUser;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _initUserAndProduct();
  }

  Future<void> _initUserAndProduct() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('id_user');
    await fetchProductDetail();
    await _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    if (idUser == null) {
      setState(() {
        isFavorite = false;
      });
      return;
    }
    final url = Uri.parse(
      '${getBaseUrl()}/favorite?id_user=$idUser&id_product=${widget.productId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isFavorite = data['isFavorite'] ?? false;
        });
      } else {
        setState(() {
          isFavorite = false;
        });
      }
    } catch (e) {
      setState(() {
        isFavorite = false;
      });
    }
  }

  Future<void> toggleFavorite() async {
    if (idUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan login untuk menambahkan ke favorit')),
      );
      return;
    }
    final url = Uri.parse('${getBaseUrl()}/favorite');
    try {
      if (!isFavorite) {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': widget.productId}),
        );
        if (response.statusCode == 201) {
          setState(() {
            isFavorite = true;
          });
        }
      } else {
        final response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_user': idUser, 'id_product': widget.productId}),
        );
        if (response.statusCode == 200) {
          setState(() {
            isFavorite = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah status favorit')));
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
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              Navigator.pop(context, true);
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
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: toggleFavorite,
                splashRadius: 24,
                tooltip:
                    isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : (product == null || product!.isEmpty)
                ? Center(child: Text('Product not found'))
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image with gradient overlay
                      Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              final imagePath = getImageAssetPath(
                                product!['product_image'],
                              );
                              return Container(
                                height: kIsWeb ? 350 : 300,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                  child:
                                      imagePath.isNotEmpty
                                          ? Image.asset(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[100],
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.image,
                                                          size: 80,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                      ),
                                                    ),
                                          )
                                          : Container(
                                            color: Colors.grey[100],
                                            child: Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 80,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                ),
                              );
                            },
                          ),
                          // Gradient overlay for better text readability
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Product Info Card
                      Container(
                        margin: EdgeInsets.all(20),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              product!['product_name'] ?? '-',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: kIsWeb ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),

                            // Price
                            Text(
                              formatRupiah(product!['product_price']),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: kIsWeb ? 18 : 22,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Status Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (product!['product_status'] ?? '')
                                                .toLowerCase() ==
                                            'ready'
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      (product!['product_status'] ?? '')
                                                  .toLowerCase() ==
                                              'ready'
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                product!['product_status'] ?? '-',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      (product!['product_status'] ?? '')
                                                  .toLowerCase() ==
                                              'ready'
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Location and Date Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Iconsax.location,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      product!['product_location'] ?? '-',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: kIsWeb ? 12 : 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatTanggal(product!['created_at']),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: kIsWeb ? 11 : 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Description Card
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.description,
                                    size: 20,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Deskripsi Produk',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: kIsWeb ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              product!['description'] ?? 'Tidak ada deskripsi',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: kIsWeb ? 13 : 15,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Contact Card
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Iconsax.whatsapp,
                                    size: 20,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Hubungi Penjual',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: kIsWeb ? 14 : 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WhatsApp',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        product!['seller_contact'] ?? '-',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: kIsWeb ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      openWhatsApp(
                                        product!['seller_contact'] ?? '',
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade500,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Iconsax.whatsapp,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
      ),
    );
  }
}
