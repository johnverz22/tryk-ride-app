import 'package:flutter/material.dart';
import '../../../../../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool isLogin = true;
  String name = '';
  String email = '';
  String password = '';
  bool loading = false;
  String? error;

void _submit() async {
  debugPrint('[AuthForm] Submit called');

  if (!_formKey.currentState!.validate()) {
    debugPrint('[AuthForm] Form validation failed');
    return;
  }

  setState(() {
    loading = true;
    error = null;
  });

  _formKey.currentState!.save();

  debugPrint('[AuthForm] Form values -> email: $email, password: $password');
  if (!isLogin) debugPrint('[AuthForm] Register mode, name: $name');

  bool success = false;

  try {
    if (isLogin) {
      debugPrint('[AuthForm] Attempting login...');
      success = await _authService.login(email, password);
    } else {
      debugPrint('[AuthForm] Attempting registration...');
      success = await _authService.register(name, email, password);
    }
    debugPrint('[AuthForm] Auth success: $success');
  } catch (e) {
    debugPrint('[AuthForm] Error during auth: $e');
    setState(() {
      loading = false;
      error = 'An error occurred. Please try again.';
    });
    return;
  }

  setState(() => loading = false);

  if (success && context.mounted) {
    debugPrint('[AuthForm] Navigating to /home');
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    debugPrint('[AuthForm] Auth failed, staying on auth screen');
    setState(() {
      error = 'Authentication failed. Try again.';
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin)
                      TextFormField(
                        key: const ValueKey('name'),
                        decoration: const InputDecoration(labelText: 'Name'),
                        onSaved: (value) => name = value!.trim(),
                        validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                      ),
                    TextFormField(
                      key: const ValueKey('email'),
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (value) => email = value!.trim(),
                      validator: (value) => value!.isEmpty ? 'Enter an email' : null,
                    ),
                    TextFormField(
                      key: const ValueKey('password'),
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      onSaved: (value) => password = value!.trim(),
                      validator: (value) => value!.length < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 20),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isLogin ? 'Login' : 'Register'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin
                          ? 'Don’t have an account? Register'
                          : 'Already have an account? Login'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
