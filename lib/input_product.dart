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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: kIsWeb ? 50 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Shoozie',
                    style: TextStyle(fontSize: 32, fontFamily: 'Gotham'),
                  ),
                  const SizedBox(height: 60),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add Product',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      hintText: 'Product Name',
                      border: UnderlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _productPriceController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'Rp 0',
                      border: UnderlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        String formatted = _formatCurrency(value);
                        _productPriceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                    },
                    validator:
                        (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: _selectedBrandId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.branding_watermark),
                      hintText: 'Select Brand',
                      border: UnderlineInputBorder(),
                    ),
                    items:
                        brands.map<DropdownMenuItem<int>>((brand) {
                          return DropdownMenuItem(
                            value: brand['id_brand'],
                            child: Text(brand['brand_name']),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => _selectedBrandId = val),
                    validator: (v) => v == null ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, color: Colors.grey[600]),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _productImageBase64 != null
                                    ? 'Image Selected'
                                    : 'Select Product Image',
                                style: TextStyle(
                                  color:
                                      _productImageBase64 != null
                                          ? Colors.black
                                          : Colors.grey[600],
                                ),
                              ),
                              if (_productImageBase64 != null)
                                Text(
                                  'Image uploaded as base64',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                          ),
                          child: Text('Upload'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _productLocationController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'Product Location',
                      border: UnderlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _sellerContactController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: 'Seller Contact',
                      border: UnderlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600]),
                            SizedBox(width: 16),
                            Text(
                              'Product Status',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Ready'),
                                value: 'Ready',
                                groupValue: _productStatus,
                                onChanged: (String? value) {
                                  setState(() {
                                    _productStatus = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Sold Out'),
                                value: 'Sold Out',
                                groupValue: _productStatus,
                                onChanged: (String? value) {
                                  setState(() {
                                    _productStatus = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.description_outlined),
                      hintText: 'Description',
                      border: UnderlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator:
                        (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          vertical: kIsWeb ? 23 : 10,
                          horizontal: kIsWeb ? 20 : 0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Add Product',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
