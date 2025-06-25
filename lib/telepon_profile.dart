import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditPhonePage extends StatefulWidget {
  const EditPhonePage({super.key});
  @override
  EditPhonePageState createState() => EditPhonePageState();
}

class EditPhonePageState extends State<EditPhonePage> {
  final TextEditingController _phoneController = TextEditingController();
  final int maxLength = 15;

  @override
  void initState() {
    super.initState();
    _fetchPhone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');
    if (idUser == null) return;
    final url = Uri.parse(getBaseUrl() + '/users/' + idUser.toString());
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['nohp_user'] != null) {
          setState(() {
            _phoneController.text = data['nohp_user'];
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _savePhone() async {
    String phone = _phoneController.text.trim();
    if (phone.isNotEmpty && phone.length <= maxLength) {
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
          body: jsonEncode({'nohp_user': phone}),
        );
        if (response.statusCode == 200) {
          Navigator.pop(context, true); // Kembali dan trigger refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal update nomor: \\${response.body}')),
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
            'Nomor tidak boleh kosong dan maksimal $maxLength karakter',
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
          'Telepon',
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
        actions: [IconButton(icon: Icon(Icons.check), onPressed: _savePhone)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Colors.grey[300],
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: 'No. Handphone',
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
