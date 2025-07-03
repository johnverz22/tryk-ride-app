import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 32),
        Text(
          'Or continue with',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        const _SocialBtn(
          icon: FontAwesomeIcons.google,
          text: 'Continue with Google',
          color: Color(0xFFDB4437),
        ),
        const SizedBox(height: 12),
        const _SocialBtn(
          icon: FontAwesomeIcons.facebookF,
          text: 'Continue with Facebook',
          color: Color(0xFF1877F2),
        ),
        const SizedBox(height: 12),
        const _SocialBtn(
          icon: FontAwesomeIcons.xTwitter,
          text: 'Continue with X',
          color: Colors.black,
        ),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _SocialBtn({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => debugPrint('$text tapped'),
      icon: FaIcon(icon, color: Colors.white),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
