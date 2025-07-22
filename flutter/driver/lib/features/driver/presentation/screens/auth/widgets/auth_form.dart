import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';

// A reusable animation widget for a polished slide-and-fade effect.
class _AnimatedSlideFade extends StatelessWidget {
  final Widget child;
  final bool isVisible;

  const _AnimatedSlideFade({required this.child, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0.0, -0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: isVisible ? child : const SizedBox.shrink(),
    );
  }
}

class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({super.key});

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  void _submitForm() {
    // Hide keyboard on submit
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    ref.read(authControllerProvider).submit(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isRegisterMode = !controller.isLogin;

    // --- UX IMPROVEMENT: Proactive button state ---
    // The button is disabled if loading, or if it's in register mode AND terms are not agreed to.
    final isButtonDisabled =
        controller.loading || (isRegisterMode && !_agreedToTerms);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Animated Title ---
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Text(
              controller.isLogin ? 'Welcome Back!' : 'Create Account',
              key: ValueKey(controller.isLogin),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // --- Animated Fields for Registration ---
          _AnimatedSlideFade(
            isVisible: isRegisterMode,
            child: const _NameField(),
          ),
          const _EmailField(),
          const SizedBox(height: 16),
          _AnimatedSlideFade(
            isVisible: isRegisterMode,
            child: const _PhoneField(),
          ),

          // --- Password Field ---
          TextFormField(
            controller: controller.passwordController,
            obscureText: _obscurePassword,
            decoration: _inputDecoration(
              context,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) => val == null || val.length < 8
                ? 'Password must be at least 8 characters'
                : null,
          ),
          const SizedBox(height: 16),

          // --- Animated Error Message ---
          _AnimatedSlideFade(
            isVisible: controller.error != null,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    // Use Flexible to prevent overflow
                    child: Text(
                      controller.error ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Animated Terms and Conditions ---
          _AnimatedSlideFade(
            isVisible: isRegisterMode,
            child: _TermsAndConditions(
              value: _agreedToTerms,
              onChanged: (value) =>
                  setState(() => _agreedToTerms = value ?? false),
            ),
          ),
          const SizedBox(height: 20),

          // --- Submit Button with Loading State & Smooth Disabled Transition ---
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isButtonDisabled ? 0.5 : 1.0,
            child: FilledButton(
              onPressed: isButtonDisabled ? null : _submitForm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.primaryColor,
              ),
              child: controller.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      controller.isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Toggle between Login/Register ---
          TextButton(
            onPressed: controller.toggleMode,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                children: [
                  TextSpan(
                    text: controller.isLogin
                        ? "Don't have an account? "
                        : 'Already have an account? ',
                  ),
                  TextSpan(
                    text: controller.isLogin ? 'Sign up' : 'Sign in',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
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

// --- Field Widgets ---

class _NameField extends ConsumerWidget {
  const _NameField();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller.nameController,
        textCapitalization: TextCapitalization.words,
        decoration: _inputDecoration(
          context,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
        ),
        validator: (val) =>
            val == null || val.trim().isEmpty ? 'Please enter your name' : null,
      ),
    );
  }
}

class _EmailField extends ConsumerWidget {
  const _EmailField();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return TextFormField(
      controller: controller.emailController,
      decoration: _inputDecoration(
        context,
        label: 'Email Address',
        icon: Icons.email_outlined,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (val) => val == null || !regex.hasMatch(val)
          ? 'Please enter a valid email address'
          : null,
    );
  }
}

class _PhoneField extends ConsumerWidget {
  const _PhoneField();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(authControllerProvider);
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller.phoneController,
        keyboardType: TextInputType.phone,
        decoration: _inputDecoration(
          context,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
        ),
        validator: (val) => val == null || !phoneRegex.hasMatch(val)
            ? 'Please enter a valid phone number'
            : null,
      ),
    );
  }
}

class _TermsAndConditions extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsAndConditions({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // --- UX FIX: Reduced vertical padding to tighten the layout ---
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // --- UX FIX: Constrain checkbox size and reduce tap target ---
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: theme.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8), // --- UX FIX: Reduced spacing ---
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Navigate to Terms of Service screen
                        debugPrint('Navigate to Terms of Service');
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Navigate to Privacy Policy screen
                        debugPrint('Navigate to Privacy Policy');
                      },
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

// --- A more refined Input Decoration Helper ---
InputDecoration _inputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: theme.colorScheme.primary.withOpacity(0.8)),
    suffixIcon: suffix,
    filled: true,
    fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    ),
    // --- UX FIX: Make error border consistent and more prominent ---
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    ),
  );
}
