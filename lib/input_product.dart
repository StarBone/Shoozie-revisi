import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class InputProduct extends StatefulWidget {
  const InputProduct({super.key});

  @override
  State<InputProduct> createState() => _InputProductState();
}

class _InputProductState extends State<InputProduct> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productLocationController =
      TextEditingController();
  final TextEditingController _sellerContactController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int? _selectedBrandId;
  String _productStatus = 'Ready'; // Default value for radio button
  String? _productImageBase64;
  List<dynamic> brands = [];

  @override
  void initState() {
    super.initState();
    fetchBrands();
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

  Future<void> _pickImage() async {
    // Simple text input for base64 string
    TextEditingController base64Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Product Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For now, you can paste a base64 image string or just enter a placeholder text:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              TextField(
                controller: base64Controller,
                decoration: InputDecoration(
                  hintText: 'Paste base64 string or enter "placeholder"',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (base64Controller.text.isNotEmpty) {
                  setState(() {
                    _productImageBase64 = base64Controller.text;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Image data added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';

    // Remove all non-digit characters
    String numericString = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericString.isEmpty) return '';

    // Convert to number and format
    int number = int.parse(numericString);
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  int _parsePrice(String formattedPrice) {
    if (formattedPrice.isEmpty) return 0;
    String numericString = formattedPrice.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numericString) ?? 0;
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('${getBaseUrl()}/product');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "product_name": _productNameController.text,
        "product_price": _parsePrice(_productPriceController.text),
        "product_image": _productImageBase64 ?? '',
        "product_location": _productLocationController.text,
        "seller_contact": _sellerContactController.text,
        "product_status": _productStatus,
        "description": _descriptionController.text,
        "id_brand": _selectedBrandId,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Produk berhasil ditambahkan'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? 'Gagal menambahkan produk')),
      );
    }
  }

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080'; // android
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: kIsWeb ? 120 : 32,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_business_outlined,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Shoozie',
                    style: TextStyle(
                      fontSize: 36,
                      fontFamily: 'Gotham',
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your product to the marketplace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Add Product Form Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Product',
                          style: TextStyle(
                            fontSize: 28,
                            fontFamily: 'Gotham',
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fill in the product details to list your item',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Product Name Field
                        _buildFormField(
                          label: 'Product Name',
                          controller: _productNameController,
                          icon: Icons.shopping_bag_outlined,
                          hintText: 'Enter product name',
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Product name is required'
                                      : null,
                        ),
                        const SizedBox(height: 24),
                        // Brand Field
                        _buildBrandField(),
                        const SizedBox(height: 24),
                        // Price Field
                        _buildPriceField(),
                        const SizedBox(height: 24),
                        // Image Upload Field
                        _buildImageUploadField(),
                        const SizedBox(height: 24),
                        // Product Status Field
                        _buildStatusField(),
                        const SizedBox(height: 24),
                        // Location Field
                        _buildFormField(
                          label: 'Product Location',
                          controller: _productLocationController,
                          icon: Icons.location_on_outlined,
                          hintText: 'Enter product location',
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Location is required'
                                      : null,
                        ),
                        const SizedBox(height: 24),
                        // Seller Contact Field
                        _buildFormField(
                          label: 'Seller Contact',
                          controller: _sellerContactController,
                          icon: Icons.phone_outlined,
                          hintText: 'Enter contact number',
                          keyboardType: TextInputType.phone,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Contact is required'
                                      : null,
                        ),
                        const SizedBox(height: 24),
                        // Description Field
                        _buildFormField(
                          label: 'Description',
                          controller: _descriptionController,
                          icon: Icons.description_outlined,
                          hintText: 'Enter product description',
                          maxLines: 3,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Description is required'
                                      : null,
                        ),
                        const SizedBox(height: 32),
                        // Add Product Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _addProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Price',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _productPriceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isNotEmpty) {
              String formatted = _formatCurrency(value);
              _productPriceController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.attach_money,
              color: Colors.grey.shade500,
              size: 20,
            ),
            hintText: 'Rp 0',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Price is required' : null,
        ),
      ],
    );
  }

  Widget _buildBrandField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brand',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedBrandId,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.branding_watermark,
              color: Colors.grey.shade500,
              size: 20,
            ),
            hintText: 'Select a brand',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items:
              brands.map<DropdownMenuItem<int>>((brand) {
                return DropdownMenuItem(
                  value: brand['id_brand'],
                  child: Text(
                    brand['brand_name'],
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                );
              }).toList(),
          onChanged: (val) => setState(() => _selectedBrandId = val),
          validator: (v) => v == null ? 'Brand is required' : null,
        ),
      ],
    );
  }

  Widget _buildImageUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.image_outlined, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productImageBase64 != null
                          ? 'Image Selected'
                          : 'No image selected',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color:
                            _productImageBase64 != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                      ),
                    ),
                    if (_productImageBase64 != null)
                      Text(
                        'Image uploaded successfully',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Upload',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Status',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _productStatus == 'Ready'
                            ? Colors.black
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      'Ready',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            _productStatus == 'Ready'
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    value: 'Ready',
                    groupValue: _productStatus,
                    activeColor: Colors.white,
                    onChanged: (String? value) {
                      setState(() {
                        _productStatus = value!;
                      });
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _productStatus == 'Sold Out'
                            ? Colors.black
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      'Sold Out',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            _productStatus == 'Sold Out'
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    value: 'Sold Out',
                    groupValue: _productStatus,
                    activeColor: Colors.white,
                    onChanged: (String? value) {
                      setState(() {
                        _productStatus = value!;
                      });
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
