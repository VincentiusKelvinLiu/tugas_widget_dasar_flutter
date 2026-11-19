import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorText = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final Logger _logger = Logger();

  void _signIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String inputUsername = _usernameController.text.trim();
    final String inputPassword = _passwordController.text.trim();
    _logger.d('Sign in attempt');
    final String encryptedUsername = prefs.getString('username') ?? '';
    final String encryptedPassword = prefs.getString('password') ?? '';
    final String keyString = prefs.getString('key') ?? '';
    final String ivString = prefs.getString('iv') ?? '';

    if (encryptedUsername.isEmpty || encryptedPassword.isEmpty || keyString.isEmpty || ivString.isEmpty) {
      setState(() {
        _errorText =
            'Data akun belum tersedia. Silakan daftar ulang.';
      });
      return;
    }
    final encrypt.Key key = encrypt.Key.fromBase64(keyString);
    final encrypt.IV iv = encrypt.IV.fromBase64(ivString);
    final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key));
    final String savedUsername = encrypter.decrypt64(encryptedUsername, iv: iv);
    final String savedPassword = encrypter.decrypt64(encryptedPassword, iv: iv);

    if (inputUsername != savedUsername || inputPassword != savedPassword) {
      setState(() {
        _errorText =
            'Nama pengguna atau kata sandi salah';
      });

      _logger.e(
        'Username or password is incorrect',
      );
      return;
    }

    setState(() {
      _errorText = '';
    });
    await prefs.setBool('isSignedIn', true);
    _logger.d('Sign in succeeded');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
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
                    onPressed: _signIn,
                    child: const Text('Sign In'),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text('Belum punya akun? Daftar di sini.'),
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