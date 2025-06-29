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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [],
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Gotham',
            color: Colors.black87,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData == null
              ? Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Colors.blue.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Access Your Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontFamily: 'Gotham',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please log in to view and manage your profile information',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
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
              )
              : RefreshIndicator(
                onRefresh: _refreshUserData,
                child: ListView(
                  children: [
                    // Profile Header
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  userData != null
                                      ? _getProfileColor(
                                        userData!['id_user'] ?? 0,
                                      )
                                      : Colors.grey[400],
                              child: Text(
                                userData != null &&
                                        userData!['username'] != null &&
                                        userData!['username'].isNotEmpty
                                    ? userData!['username'][0].toUpperCase()
                                    : '',
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userData?['username'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Gotham',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData?['email'] ?? 'No email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Information Cards
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          buildInfoTile(
                            context,
                            title: 'Nama',
                            value: userData?['username'] ?? '-',
                            onTap: () async {
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
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          buildInfoTile(
                            context,
                            title: 'Alamat',
                            value: userData?['address'] ?? '-',
                            onTap: () async {
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
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          buildInfoTile(
                            context,
                            title: 'Jenis Kelamin',
                            value:
                                (() {
                                  final jk = userData?['gender']?.toString();
                                  return jk == '1'
                                      ? 'Laki-laki'
                                      : jk == '2'
                                      ? 'Perempuan'
                                      : '-';
                                })(),
                            onTap: () async {
                              final result = await showModalBottomSheet<String>(
                                context: context,
                                builder: (context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 20),
                                      ListTile(
                                        title: const Text(
                                          'Laki-laki',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        onTap:
                                            () => Navigator.pop(context, '1'),
                                      ),
                                      ListTile(
                                        title: const Text(
                                          'Perempuan',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        onTap:
                                            () => Navigator.pop(context, '2'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result != null &&
                                  result != userData?['gender']?.toString()) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final idUser = prefs.getInt('id_user');
                                if (idUser != null) {
                                  final url = Uri.parse(
                                    getBaseUrl() +
                                        '/users/' +
                                        idUser.toString(),
                                  );
                                  await http.patch(
                                    url,
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({'gender': result}),
                                  );
                                  _refreshUserData();
                                }
                              }
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          buildInfoTile(
                            context,
                            title: 'Tanggal Lahir',
                            value:
                                (() {
                                  final tgl = userData?['birthday'];
                                  if (tgl == null || tgl == '-' || tgl == '')
                                    return '-';
                                  try {
                                    if (tgl is String && tgl.length >= 10) {
                                      return tgl.substring(0, 10);
                                    }
                                    return tgl.toString().substring(0, 10);
                                  } catch (e) {
                                    return tgl.toString();
                                  }
                                })(),
                            onTap: () async {
                              DateTime? initialDate;
                              final tgl = userData?['birthday'];
                              if (tgl != null && tgl != '-' && tgl != '') {
                                try {
                                  String dateOnly = tgl.toString().substring(
                                    0,
                                    10,
                                  );
                                  List<String> parts = dateOnly.split('-');
                                  if (parts.length == 3) {
                                    int year = int.parse(parts[0]);
                                    int month = int.parse(parts[1]);
                                    int day = int.parse(parts[2]);
                                    initialDate = DateTime(year, month, day);
                                  }
                                } catch (e) {
                                  print(
                                    'Error parsing initial date: $tgl, error: $e',
                                  );
                                }
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    initialDate ?? DateTime(2000, 1, 1),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final idUser = prefs.getInt('id_user');
                                if (idUser != null) {
                                  final url = Uri.parse(
                                    getBaseUrl() +
                                        '/users/' +
                                        idUser.toString(),
                                  );
                                  String formattedDate =
                                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  await http.patch(
                                    url,
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'birthday': formattedDate,
                                    }),
                                  );
                                  _refreshUserData();
                                }
                              }
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          buildInfoTile(
                            context,
                            title: 'No. Hp',
                            value: userData?['contact'] ?? '-',
                            onTap: () async {
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Product(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom navigation
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
                  icon: const Icon(Iconsax.heart_copy, color: Colors.grey),
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
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    maxLines: null, // Allow unlimited lines
                    overflow: TextOverflow.visible, // Don't cut off text
                  ),
                ],
              ),
            ),
            // Commented out edit button for cleaner look
            // if (onTap != null)
            //   Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: Colors.grey.shade100,
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //     child: Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
            //   ),
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
