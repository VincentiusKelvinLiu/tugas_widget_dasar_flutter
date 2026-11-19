import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger _logger = Logger();

  String _errorText = '';
  bool _obscurePassword = true;

  void _signUp() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String fullName = _fullNameController.text.trim();
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (password.length < 8 ||
        !password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[a-z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      setState(() {
        _errorText = 'Minimal 8 karakter, kombinasi huruf besar, huruf kecil, angka, dan karakter khusus';
      });
      return;
    }

    setState(() {
      _errorText = '';
    });

    _logger.d('Sign up attempt');
    final encrypt.Key key = encrypt.Key.fromLength(32);
    final encrypt.IV iv = encrypt.IV.fromLength(16);
    final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypt.Encrypted encryptedFullName = encrypter.encrypt(fullName, iv: iv);
    final encrypt.Encrypted encryptedUsername = encrypter.encrypt(username, iv: iv);
    final encrypt.Encrypted encryptedPassword = encrypter.encrypt(password, iv: iv);

    await prefs.setString(
      'fullName',
      encryptedFullName.base64,
    );
    await prefs.setString(
      'username',
      encryptedUsername.base64,
    );
    await prefs.setString(
      'password',
      encryptedPassword.base64,
    );
    await prefs.setString('key', key.base64);
    await prefs.setString('iv', iv.base64);
    _logger.d('Sign up succeeded');

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/signin',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengguna',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      errorText: _errorText.isNotEmpty ? _errorText : null,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Sign Up'),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Sudah punya akun? Masuk di sini.'),
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