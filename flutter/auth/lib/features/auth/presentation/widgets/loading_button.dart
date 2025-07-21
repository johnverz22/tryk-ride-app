import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isOutlined;

  const LoadingButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: _buildButtonContent(context),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: _buildButtonContent(context),
            ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
              ),
            )
          : Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOutlined
                    ? const Color(0xFF1C1C1C)
                    : const Color(0xFFFFFFFF),
              ),
            ),
    );
  }
}
