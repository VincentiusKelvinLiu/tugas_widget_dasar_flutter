import 'package:flutter/material.dart';
import '../widgets/profile_info_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isSignedIn = false;
  String fullName = 'Vincentius Kelvin Liu';
  String userName = 'Kelvin';
  int favoriteCandiCount = 3;

  void signIn() {
    Navigator.pushNamed(context, '/signin');
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encryptedFullName = prefs.getString('fullName') ?? '';
    final String encryptedUsername = prefs.getString('username') ?? '';
    final String keyString = prefs.getString('key') ?? '';
    final String ivString = prefs.getString('iv') ?? '';
    String decryptedFullName = 'Belum ada data';
    String decryptedUsername = 'Belum ada data';

    if (keyString.isNotEmpty && ivString.isNotEmpty) {
      final encrypt.Key key = encrypt.Key.fromBase64(keyString);
      final encrypt.IV iv = encrypt.IV.fromBase64(ivString);
      final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key));

      if (encryptedFullName.isNotEmpty) {
        decryptedFullName = encrypter.decrypt64(
          encryptedFullName,
          iv: iv,
        );
      }

      if (encryptedUsername.isNotEmpty) {
        decryptedUsername = encrypter.decrypt64(
          encryptedUsername,
          iv: iv,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      isSignedIn = prefs.getBool('isSignedIn') ?? false;
      fullName = decryptedFullName;
      userName = decryptedUsername;
    });
  }

  Future<void> signOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isSignedIn', false);
    await prefs.setString('fullName', '');
    await prefs.setString('username', '');
    await prefs.setString('password', '');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  Future<void> editFullName() async {
    String newFullName = fullName;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Nama Lengkap'),
          content: TextFormField(
            initialValue: fullName,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
            ),
            onChanged: (String value) {
              newFullName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final String updatedFullName =newFullName.trim();
                if (updatedFullName.isEmpty) return;
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                final String keyString = prefs.getString('key') ?? '';
                final String ivString = prefs.getString('iv') ?? '';

                if (keyString.isEmpty || ivString.isEmpty) {
                  return;
                }

                final encrypt.Key key = encrypt.Key.fromBase64(keyString);
                final encrypt.IV iv = encrypt.IV.fromBase64(ivString);
                final encrypt.Encrypter encrypter = encrypt.Encrypter(
                  encrypt.AES(key),
                );
                final encrypt.Encrypted encryptedName = encrypter.encrypt(
                  updatedFullName,
                  iv: iv,
                );
                await prefs.setString(
                  'fullName',
                  encryptedName.base64,
                );

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                setState(() {
                  fullName = updatedFullName;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.deepPurple,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // TODO: 2. Buat bagian ProfileHeader yang berisi gambar profil
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 200 - 50),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(
                              'images/placeholder_image.png',
                            ),
                          ),
                        ),
                        if (isSignedIn)
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.camera_alt,
                              color: Colors.deepPurple[50],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.deepPurple[100]),
                const SizedBox(height: 4),

                ProfileInfoItem(
                  icon: Icons.lock,
                  label: 'Pengguna',
                  value: userName,
                  iconColor: Colors.amber,
                ),

                const SizedBox(height: 4),
                Divider(color: Colors.deepPurple[100]),
                const SizedBox(height: 4),

                ProfileInfoItem(
                  icon: Icons.person,
                  label: 'Nama',
                  value: fullName,
                  showEditIcon: isSignedIn,
                  onEditPressed: editFullName,
                  iconColor: Colors.blue,
                ),

                const SizedBox(height: 4),
                Divider(color: Colors.deepPurple[100]),
                const SizedBox(height: 4),

                ProfileInfoItem(
                  icon: Icons.favorite,
                  label: 'Favorit',
                  value: favoriteCandiCount > 0 ? '$favoriteCandiCount' : '',
                  iconColor: Colors.red,
                ),

                const SizedBox(height: 4),
                Divider(color: Colors.deepPurple[100]),
                const SizedBox(height: 20),

                isSignedIn
                    ? TextButton(
                        onPressed: signOut,
                        child: const Text('Sign Out'),
                      )
                    : TextButton(
                        onPressed: signIn,
                        child: const Text('Sign In'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}