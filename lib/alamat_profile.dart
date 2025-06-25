import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditAddressPage extends StatefulWidget {
  const EditAddressPage({super.key});
  @override
  EditAddressPageState createState() => EditAddressPageState();
}

class EditAddressPageState extends State<EditAddressPage> {
  final TextEditingController _addressController = TextEditingController();
  final int maxLength = 250;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');
    if (idUser == null) return;
    final url = Uri.parse(getBaseUrl() + '/users/' + idUser.toString());
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['alamat_user'] != null) {
          setState(() {
            _addressController.text = data['alamat_user'];
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _saveAddress() async {
    String address = _addressController.text.trim();
    if (address.isNotEmpty && address.length <= maxLength) {
      final prefs = await SharedPreferences.getInstance();
      final idUser = prefs.getInt('id_user');
      if (idUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User tidak ditemukan.')));
        return;
      }
      final url = Uri.parse(getBaseUrl() + '/users/' + idUser.toString());
      try {
        final response = await http.patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'alamat_user': address}),
        );
        if (response.statusCode == 200) {
          Navigator.pop(context, true); // Kembali dan trigger refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal update alamat: \\${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan koneksi.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alamat tidak boleh kosong dan maksimal $maxLength karakter',
          ),
        ),
      );
    }
  }

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080'; // Android
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Alamat',
          style: TextStyle(
            fontFamily: 'Gotham',
            color: Colors.black,
            fontSize: 30,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [IconButton(icon: Icon(Icons.check), onPressed: _saveAddress)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Colors.grey[300],
          child: TextField(
            controller: _addressController,
            maxLines: 5,
            maxLength: maxLength,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Alamat',
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
