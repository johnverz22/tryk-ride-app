import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:user/features/user/data/models/user_model.dart';
import 'package:user/features/user/presentation/pages/screens/main_navigation_screen.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../providers/user_provider.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    _formKey.currentState!.save();

    bool success = false;
    try {
      if (isLogin) {
        success = await _authService.login(email, password, context);
      } else {
        success = await _authService.register(name, email, password, context);
      }
    } catch (_) {
      setState(() {
        loading = false;
        error = 'An error occurred. Please try again.';
      });
      return;
    }

    if (!mounted) return;

    setState(() => loading = false);

    if (success) {
      final token = await _authService.getToken();
      final userData = await _authService.getUser();

      if (token != null && userData != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(UserModel.fromJson(json: userData), token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        setState(() => error = 'Could not load user data.');
      }
    } else {
      setState(() => error = 'Authentication failed. Try again.');
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscure = false,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType inputType = TextInputType.text,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: theme.primaryColor),
        labelText: label,
        labelStyle: TextStyle(color: theme.primaryColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: TextStyle(color: theme.primaryColor),
      cursorColor: theme.primaryColor,
      obscureText: obscure,
      keyboardType: inputType,
      onSaved: onSaved,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Header background
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(top: 50),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLogin ? 'Login' : 'Register',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!isLogin)
                          _buildTextField(
                            label: 'Name',
                            icon: Icons.person,
                            onSaved: (val) => name = val!.trim(),
                            validator: (val) =>
                                val!.isEmpty ? 'Enter your name' : null,
                          ),
                        if (!isLogin) const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Email',
                          icon: Icons.email,
                          inputType: TextInputType.emailAddress,
                          onSaved: (val) => email = val!.trim(),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter a valid email';
                            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(val)) return 'Enter a valid email address';
                            return null;
                          }
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Password',
                          icon: Icons.lock,
                          obscure: true,
                          onSaved: (val) => password = val!.trim(),
                          validator: (val) =>
                              val!.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 16),

                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        loading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: theme.primaryColor,
                                ),
                                child: Text(
                                  isLogin ? 'Login' : 'Register',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () =>
                              setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin
                                ? 'Don’t have an account? Register'
                                : 'Already have an account? Login',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),

                        const Divider(height: 32),
                        Text(
                          'Or continue with',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Google Button
                        ElevatedButton.icon(
                          onPressed: () => debugPrint('Google sign in'),
                          icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                          label: const Text('Continue with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB4437), // Google red
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Facebook Button
                        ElevatedButton.icon(
                          onPressed: () => debugPrint('Facebook sign in'),
                          icon: const FaIcon(FontAwesomeIcons.facebookF, color: Colors.white),
                          label: const Text('Continue with Facebook'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // X (Twitter) Button
                        ElevatedButton.icon(
                          onPressed: () => debugPrint('X sign in'),
                          icon: const FaIcon(FontAwesomeIcons.xTwitter, color: Colors.white),
                          label: const Text('Continue with X'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
