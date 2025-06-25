import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditNamePage extends StatefulWidget {
  const EditNamePage({super.key});
  @override
  EditNamePageState createState() => EditNamePageState();
}

class EditNamePageState extends State<EditNamePage> {
  final TextEditingController _nameController = TextEditingController();
  final int maxLength = 100;

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');
    if (idUser == null) return;
    final url = Uri.parse(getBaseUrl() + '/users/' + idUser.toString());
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['nama_user'] != null) {
          setState(() {
            _nameController.text = data['nama_user'];
          });
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    String name = _nameController.text.trim();
    if (name.isNotEmpty && name.length <= maxLength) {
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
          body: jsonEncode({'nama_user': name}),
        );
        if (response.statusCode == 200) {
          Navigator.pop(context, true); // Kembali dan trigger refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal update nama: ${response.body}')),
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
            'Nama tidak boleh kosong dan maksimal $maxLength karakter',
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
          'Edit Name',
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
        actions: [IconButton(icon: Icon(Icons.check), onPressed: _saveName)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.grey[300],
              child: TextField(
                controller: _nameController,
                maxLength: maxLength,
                decoration: InputDecoration(
                  hintText: 'Nama',
                  counterText: '', // Sembunyikan counter bawaan
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text('*Only 100 Character', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
