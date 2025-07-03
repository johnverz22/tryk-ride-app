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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            controller.isLogin ? 'Login' : 'Register',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          if (!controller.isLogin) const _NameField(),

          const _EmailField(),
          const SizedBox(height: 16),

          const _PasswordField(),
          const SizedBox(height: 16),

          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          controller.loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      controller.submit(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    controller.isLogin ? 'Login' : 'Register',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.toggleMode,
            child: Text(
              controller.isLogin
                  ? 'Don’t have an account? Register'
                  : 'Already have an account? Login',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends ConsumerWidget {
  const _NameField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final theme = Theme.of(context);
    return Column(
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: _decoration('Name', Icons.person, theme),
          validator: (val) =>
              val == null || val.isEmpty ? 'Enter your name' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _EmailField extends ConsumerWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final theme = Theme.of(context);
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    return TextFormField(
      controller: controller.emailController,
      decoration: _decoration('Email', Icons.email, theme),
      keyboardType: TextInputType.emailAddress,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Enter a valid email';
        return regex.hasMatch(val) ? null : 'Invalid email address';
      },
    );
  }
}

class _PasswordField extends ConsumerWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller.passwordController,
      decoration: _decoration('Password', Icons.lock, theme),
      obscureText: true,
      validator: (val) =>
          val == null || val.length < 6 ? 'Min 6 characters' : null,
    );
  }
}

InputDecoration _decoration(String label, IconData icon, ThemeData theme) {
  return InputDecoration(
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
  );
}
