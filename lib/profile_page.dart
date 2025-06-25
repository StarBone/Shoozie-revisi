import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shoozie/alamat_profile.dart';
import 'package:shoozie/favorite_page.dart';
import 'package:shoozie/login_page.dart';
import 'package:shoozie/name_profile.dart';
import 'package:shoozie/product_page.dart';
import 'package:shoozie/register_page.dart';
import 'package:shoozie/telepon_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getInt('id_user');
    if (idUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final url = Uri.parse('${getBaseUrl()}/users/$idUser');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
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

  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080'; // Android
    }
  }

  Future<void> _refreshUserData() async {
    await fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [],
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Gotham',
            color: Colors.black,
            fontSize: 30,
          ),
        ),
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('If you want to add Profile'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 70),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('or'),
                    const SizedBox(height: 3),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 70),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _refreshUserData,
                child: ListView(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                userData != null
                                    ? _getProfileColor(
                                      userData!['id_user'] ?? 0,
                                    )
                                    : Colors.grey[400],
                            child: Text(
                              userData != null &&
                                      userData!['nama_user'] != null &&
                                      userData!['nama_user'].isNotEmpty
                                  ? userData!['nama_user'][0].toUpperCase()
                                  : '',
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    buildInfoTile(
                      context,
                      title: 'Nama',
                      value: userData?['nama_user'] ?? '-',
                      onChevronTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditNamePage(),
                          ),
                        );
                        if (result == true) {
                          _refreshUserData();
                        }
                      },
                    ),
                    buildInfoTile(
                      context,
                      title: 'Alamat',
                      value:
                          (() {
                            final alamat = userData?['alamat_user'] ?? '-';
                            if (alamat == '-') return '-';
                            final cleanAlamat =
                                alamat
                                    .replaceAll(RegExp(r'[\n\r]+'), ' ')
                                    .replaceAll(RegExp(r'\s+'), ' ')
                                    .trim();
                            final words = cleanAlamat.split(' ');
                            final limited =
                                words.length <= 10
                                    ? cleanAlamat
                                    : words.take(10).join(' ') + '...';
                            const maxLength = 20;
                            if (limited.length > maxLength) {
                              return limited.substring(0, maxLength) + '...';
                            }
                            return limited;
                          })(),
                      onChevronTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditAddressPage(),
                          ),
                        );
                        if (result == true) {
                          _refreshUserData();
                        }
                      },
                    ),
                    buildInfoTile(
                      context,
                      title: 'Jenis Kelamin',
                      value:
                          (() {
                            final jk =
                                userData?['jeniskelamin_user']?.toString();
                            return jk == '1'
                                ? 'Laki-laki'
                                : jk == '2'
                                ? 'Perempuan'
                                : '-';
                          })(),
                      onChevronTap: () async {
                        final result = await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 20),
                                ListTile(
                                  title: Text(
                                    'Laki-laki',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(context, '1'),
                                ),
                                ListTile(
                                  title: Text(
                                    'Perempuan',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(context, '2'),
                                ),
                              ],
                            );
                          },
                        );
                        if (result != null &&
                            result !=
                                userData?['jeniskelamin_user']?.toString()) {
                          final prefs = await SharedPreferences.getInstance();
                          final idUser = prefs.getInt('id_user');
                          if (idUser != null) {
                            final url = Uri.parse(
                              getBaseUrl() + '/users/' + idUser.toString(),
                            );
                            await http.patch(
                              url,
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({'jeniskelamin_user': result}),
                            );
                            _refreshUserData();
                          }
                        }
                      },
                    ),
                    buildInfoTile(
                      context,
                      title: 'Tanggal Lahir',
                      value:
                          (() {
                            final tgl = userData?['tgllahir_user'];
                            if (tgl == null || tgl == '-') return '-';
                            // Ambil hanya tanggal (tanpa jam)
                            if (tgl is String && tgl.length >= 10) {
                              return tgl.substring(0, 10);
                            }
                            return tgl.toString();
                          })(),
                      onChevronTap: () async {
                        DateTime? initialDate;
                        final tgl = userData?['tgllahir_user'];
                        if (tgl != null && tgl != '-') {
                          try {
                            initialDate = DateTime.parse(
                              tgl.toString().substring(0, 10),
                            );
                          } catch (_) {}
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          final prefs = await SharedPreferences.getInstance();
                          final idUser = prefs.getInt('id_user');
                          if (idUser != null) {
                            final url = Uri.parse(
                              getBaseUrl() + '/users/' + idUser.toString(),
                            );
                            await http.patch(
                              url,
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'tgllahir_user':
                                    picked.toIso8601String().split('T')[0],
                              }),
                            );
                            _refreshUserData();
                          }
                        }
                      },
                    ),
                    buildInfoTile(
                      context,
                      title: 'No. Hp',
                      value: userData?['nohp_user'] ?? '-',
                      onChevronTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPhonePage(),
                          ),
                        );
                        if (result == true) {
                          _refreshUserData();
                        }
                      },
                    ),
                    buildInfoTile(
                      context,
                      title: 'Email',
                      value: userData?['email_user'] ?? '-',
                      // onChevronTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => RegisterPage(),
                      //     ),
                      //   );
                      // },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? 200 : 150,
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Product(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            vertical: kIsWeb ? 18 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: Container(
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
                  icon: const Icon(Iconsax.heart, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FavoritePage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.home_2_copy, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.user, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget buildInfoTile(
    BuildContext context, {
    required String title,
    required String value,
    VoidCallback? onChevronTap,
  }) {
    return Padding(
      padding:
          kIsWeb
              ? EdgeInsets.symmetric(horizontal: 20)
              : EdgeInsets.only(left: 20),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              // padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 15, minHeight: 15),
              onPressed: onChevronTap,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProfileColor(dynamic idUser) {
    // idUser bisa int atau String, pastikan int
    int id = 0;
    if (idUser is int) {
      id = idUser;
    } else if (idUser is String) {
      id = int.tryParse(idUser) ?? 0;
    }
    // Pilihan warna unik
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[id % colors.length];
  }
}
