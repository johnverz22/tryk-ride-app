import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';

class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({super.key});

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              controller.isLogin ? 'Login' : 'Register',
              key: ValueKey(controller.isLogin),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (!controller.isLogin) const _NameField(),

          const _EmailField(),
          const SizedBox(height: 16),
          if (!controller.isLogin) const _PhoneField(),

          TextFormField(
            controller: controller.passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
              context,
              label: 'Password',
              icon: Icons.lock,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (val) =>
                val == null || val.length < 8 ? 'Min 8 characters' : null,
          ),
          const SizedBox(height: 16),

          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          if (!controller.isLogin)
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              title: const Text(
                'By signing up, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 12),
              ),
            ),

          controller.loading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      controller.submit(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    controller.isLogin ? 'Login' : 'Register',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
          const SizedBox(height: 4),

          TextButton(
            onPressed: controller.toggleMode,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(color: Colors.grey),
                children: [
                  TextSpan(
                    text: controller.isLogin
                        ? 'Don’t have an account yet? '
                        : 'Already have an account? ',
                  ),
                  TextSpan(
                    text: controller.isLogin ? 'Sign up' : 'Sign in',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Name Field ---
class _NameField extends ConsumerWidget {
  const _NameField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    return Column(
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: _inputDecoration(
            context,
            label: 'Name',
            icon: Icons.person,
          ),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// --- Email Field ---
class _EmailField extends ConsumerWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    return TextFormField(
      controller: controller.emailController,
      decoration: _inputDecoration(context, label: 'Email', icon: Icons.email),
      keyboardType: TextInputType.emailAddress,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter a valid email';
        return regex.hasMatch(val) ? null : 'Invalid email address';
      },
    );
  }
}

class _PhoneField extends ConsumerWidget {
  const _PhoneField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

    return Column(
      children: [
        TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration(
            context,
            label: 'Phone Number',
            icon: Icons.phone,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Enter your phone number';
            } else if (!phoneRegex.hasMatch(val)) {
              return 'Invalid phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// --- Input Decoration Helper ---
InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: theme.colorScheme.primary),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.grey.shade100,
    labelStyle: TextStyle(color: theme.colorScheme.primary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  );
}
