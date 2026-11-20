import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // TODO: 1. Deklarasikan variabel
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorText = '';
  bool _obscurePassword = true;

  final Logger _logger = Logger();

  // TODO: 10. Membuat metode _signUp
  Future<void> _signUp() async {
    final String name = _nameController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    // Periksa seluruh input
    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Semua data wajib diisi';
      });
      return;
    }

    // Periksa kekuatan kata sandi
    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(() {
        _errorText = 'Minimal 8 karakter, kombinasi [A-Z], [a-z], [0-9], dan karakter khusus';
      });
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Membuat key dan IV
      final encrypt.Key key = encrypt.Key.fromLength(32);
      final encrypt.IV iv = encrypt.IV.fromLength(16);

      // Membuat encrypter AES
      final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Mengenkripsi data pengguna
      final encrypt.Encrypted encryptedName = encrypter.encrypt(name, iv: iv);
      final encrypt.Encrypted encryptedUsername = encrypter.encrypt(username, iv: iv);
      final encrypt.Encrypted encryptedPassword = encrypter.encrypt(password, iv: iv);

      // Menyimpan data terenkripsi
      await prefs.setString('fullname', encryptedName.base64);
      await prefs.setString('username', encryptedUsername.base64);
      await prefs.setString('password', encryptedPassword.base64);
      await prefs.setString('key', key.base64);
      await prefs.setString('iv', iv.base64);
      await prefs.setBool('isSignedIn', false);

      _logger.i('Sign up succeeded');

      if (!mounted) return;

      setState(() {
        _errorText = '';
      });

      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e, stackTrace) {
      _logger.e(
        'Sign up failed',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _errorText = 'Gagal menyimpan data. Silakan coba lagi.';
      });
    }
  }

  // TODO: 11. Membuat metode dispose
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: 2. Pasang AppBar
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      // TODO: 3. Pasang body
      body: Center(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              // TODO: 4. Atur mainAxisAlignment dan crossAxisAlignment
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // TODO: 5. Pasang TextFormField Nama Lengkap
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                // TODO: 6. Pasang TextFormField Nama Pengguna
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Pengguna",
                    border: OutlineInputBorder(),
                  ),
                ),
                // TODO: 7. Pasang TextFormField Kata Sandi
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                      labelText: "Kata Sandi",
                      errorText: _errorText.isNotEmpty ? _errorText : null,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      )),
                  obscureText: _obscurePassword,
                ),
                // TODO: 8. Pasang ElevatedButton Sign Up
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(onPressed: _signUp, child: const Text("Sign Up")),
                // TODO: 9. Pasang TextButton Sign In
                const SizedBox(
                  height: 10,
                ),
                // TextButton(
                //     onPressed: () {},
                //     child: Text('Sudah punya akun? Masuk di sini.')
                // ),
                RichText(
                    text: TextSpan(
                        text: 'Sudah punya akun? ',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                        children: [
                      TextSpan(
                        text: 'Masuk di sini.',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                      ),
                    ]))
              ],
            ),
          ),
        ),
      )),
    );
  }
}