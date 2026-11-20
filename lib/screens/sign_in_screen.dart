import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // TODO: 1. Deklarasikan variabel
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorText = '';
  bool _obscurePassword = true;

  final Logger _logger = Logger();

  Future<Map<String, String>> _retrieveAndDecryptDataFromPrefs(SharedPreferences sharedPreferences) async {
    final String encryptedUsername = sharedPreferences.getString('username') ?? '';
    final String encryptedPassword = sharedPreferences.getString('password') ?? '';
    final String keyString = sharedPreferences.getString('key') ?? '';
    final String ivString = sharedPreferences.getString('iv') ?? '';

    // Akun belum tersedia atau sudah dihapus saat Sign Out
    if (encryptedUsername.isEmpty ||
        encryptedPassword.isEmpty ||
        keyString.isEmpty ||
        ivString.isEmpty) {
      return {};
    }

    final encrypt.Key key = encrypt.Key.fromBase64(keyString);
    final encrypt.IV iv = encrypt.IV.fromBase64(ivString);
    final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(key));

    final String decryptedUsername = encrypter.decrypt64(encryptedUsername, iv: iv);
    final String decryptedPassword = encrypter.decrypt64(encryptedPassword, iv: iv);

    return {
      'username': decryptedUsername,
      'password': decryptedPassword,
    };
  }

  Future<void> _signIn() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    // Periksa input kosong
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Nama pengguna dan kata sandi wajib diisi';
      });

      _logger.w('Username and password cannot be empty');
      return;
    }

    try {
      _logger.d('Sign in attempt');

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final Map<String, String> data = await _retrieveAndDecryptDataFromPrefs(prefs);

      // Data akun belum tersedia
      if (data.isEmpty) {
        if (!mounted) return;

        setState(() {
          _errorText = 'Data akun belum tersedia. Silakan daftar ulang.';
        });
        _logger.w('No stored credentials found');
        return;
      }

      final String decryptedUsername = data['username'] ?? '';
      final String decryptedPassword = data['password'] ?? '';

      // Periksa kecocokan data
      if (username != decryptedUsername ||password != decryptedPassword) {
        if (!mounted) return;

        setState(() {
          _errorText = 'Nama pengguna atau kata sandi salah';
        });

        _logger.w('Username or password is incorrect');
        return;
      }

      // Sign In berhasil
      await prefs.setBool('isSignedIn', true);

      if (!mounted) return;

      setState(() {
        _errorText = '';
      });

      _logger.i('Sign in succeeded');

      // Membuka halaman utama dan menghapus halaman sebelumnya
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } catch (e, stackTrace) {
      _logger.e(
        'Sign in failed',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _errorText = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: 2. Pasang AppBar
      appBar: AppBar(
        title: const Text('Sign In'),
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
                  // TODO: 5. Pasang TextFormField Nama Pengguna
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengguna',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TODO: 6. Pasang TextFormField Kata Sandi
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      errorText:
                          _errorText.isNotEmpty ? _errorText : null,
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
                  ),

                  const SizedBox(height: 20),

                  // TODO: 7. Pasang ElevatedButton Sign In
                  ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('Sign In'),
                  ),

                  const SizedBox(height: 10),

                  // TODO: 8. Pasang tombol menuju Sign Up
                  RichText(
                    text: TextSpan(
                      text: 'Belum punya akun? ',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                      children: [
                        TextSpan(
                          text: 'Daftar di sini.',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(
                                context,
                                '/signup',
                              );
                            },
                        ),
                      ],
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