import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoozie/input_product.dart';
import 'package:shoozie/detail_product.dart';

class SellerProductList extends StatefulWidget {
  const SellerProductList({super.key});

  @override
  State<SellerProductList> createState() => _SellerProductListState();
}

class _SellerProductListState extends State<SellerProductList> {
  List<dynamic> products = [];
  List<dynamic> brands = [];
  bool isLoading = true;
  String searchQuery = '';
  int? selectedBrandId;
  String selectedSortOption = 'newest';
  int? idUser;
  String? userName;

  @override
  void initState() {
    super.initState();
    _initUserAndFetch();
  }

  Future<void> _initUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('id_user');
    userName = prefs.getString('username') ?? 'Seller';

    if (idUser != null) {
      await fetchBrands();
      await fetchProducts();
    } else {
      // Redirect to login if no user
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
    }
  }

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080'; // android
    }
  }

  Future<void> fetchBrands() async {
    try {
      final response = await http.get(Uri.parse('${getBaseUrl()}/brands'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          brands = data;
        });
      }
    } catch (e) {
      print('Error fetching brands: $e');
    }
  }

  Future<void> fetchProducts() async {
    if (idUser == null) return;

    setState(() {
      isLoading = true;
    });

    // Fetch products by user ID
    String urlStr = '${getBaseUrl()}/products/user/$idUser';
    if (selectedBrandId != null) {
      urlStr += '?id_brand=$selectedBrandId';
    }

    try {
      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data;
          isLoading = false;
        });
        _sortProducts();
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to fetch products: \\${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching products: $e');
    }
  }

  void _sortProducts() {
    setState(() {
      switch (selectedSortOption) {
        case 'newest':
          products.sort(
            (a, b) => (b['id_product'] ?? 0).compareTo(a['id_product'] ?? 0),
          );
          break;
        case 'oldest':
          products.sort(
            (a, b) => (a['id_product'] ?? 0).compareTo(b['id_product'] ?? 0),
          );
          break;
        case 'price_low':
          products.sort(
            (a, b) =>
                (a['product_price'] ?? 0).compareTo(b['product_price'] ?? 0),
          );
          break;
        case 'price_high':
          products.sort(
            (a, b) =>
                (b['product_price'] ?? 0).compareTo(a['product_price'] ?? 0),
          );
          break;
        case 'name_asc':
          products.sort(
            (a, b) =>
                (a['product_name'] ?? '').compareTo(b['product_name'] ?? ''),
          );
          break;
        case 'name_desc':
          products.sort(
            (a, b) =>
                (b['product_name'] ?? '').compareTo(a['product_name'] ?? ''),
          );
          break;
      }
    });
  }

  List<dynamic> get filteredProducts {
    if (searchQuery.isEmpty) {
      return products;
    }
    return products.where((product) {
      final productName =
          (product['product_name'] ?? '').toString().toLowerCase();
      final brandName = (product['brand_name'] ?? '').toString().toLowerCase();
      final location =
          (product['product_location'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return productName.contains(query) ||
          brandName.contains(query) ||
          location.contains(query);
    }).toList();
  }

  String formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Future<void> _refreshProducts() async {
    await fetchProducts();
  }

  Future<void> _updateProductStatus(int productId, String currentStatus) async {
    final newStatus = currentStatus == 'Ready' ? 'Sold Out' : 'Ready';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Product Status'),
            content: Text(
              'Change status from "$currentStatus" to "$newStatus"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Update'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // Integrate edit product with PUT /product/:id_product/status
        final response = await http.put(
          Uri.parse('${getBaseUrl()}/product/$productId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'product_status': newStatus}),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
          await _refreshProducts();
        } else {
          print('Edit status failed: ${response.statusCode} ${response.body}');
          throw Exception('Failed to update product status');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
              'Are you sure you want to delete this product? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // Integrate delete product with DELETE /product/:id_product
        final response = await http.delete(
          Uri.parse('${getBaseUrl()}/product/$productId'),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _refreshProducts();
        } else {
          print('Delete failed: ${response.statusCode} ${response.body}');
          throw Exception('Failed to delete product');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Products',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'Gotham',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Hello, $userName',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _refreshProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Products',
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InputProduct()),
              );
              _refreshProducts();
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add New Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Products Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} product${filteredProducts.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Tap status to edit',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                    : filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _refreshProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gotham',
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Start by adding your first product',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InputProduct()),
              );
              _refreshProducts();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ProductDetailPage(productId: product['id_product']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      product['product_image'] != null &&
                              product['product_image'].isNotEmpty
                          ? Image.network(
                            product['product_image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          )
                          : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(width: 16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product['product_name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Brand Name
                    if (product['brand_name'] != null)
                      Text(
                        product['brand_name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Price
                    Text(
                      formatPrice(product['product_price']),
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location and Status
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['product_location'] ?? 'Unknown Location',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Status Button (Editable)
                    InkWell(
                      onTap:
                          () => _updateProductStatus(
                            product['id_product'],
                            product['product_status'] ?? 'Ready',
                          ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              product['product_status'] == 'Ready'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                product['product_status'] == 'Ready'
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product['product_status'] == 'Ready'
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 16,
                              color:
                                  product['product_status'] == 'Ready'
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product['product_status'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color:
                                    product['product_status'] == 'Ready'
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 12,
                              color:
                                  product['product_status'] == 'Ready'
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit_status') {
                    _updateProductStatus(
                      product['id_product'],
                      product['product_status'] ?? 'Ready',
                    );
                  } else if (value == 'delete') {
                    _deleteProduct(product['id_product']);
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'edit_status',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.blue.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text('Edit Status'),
                          ],
                        ),
                      ),
                      if ((product['product_status'] ?? '').toLowerCase() !=
                          'deleted')
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                    ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade100,
      child: Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
    );
  }
}
