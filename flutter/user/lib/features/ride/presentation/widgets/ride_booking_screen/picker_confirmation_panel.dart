import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';

class PickerConfirmationPanel extends ConsumerWidget {
  final VoidCallback onConfirm;
  final VoidCallback onAddToFavorites;

  const PickerConfirmationPanel({
    Key? key,
    required this.onConfirm,
    required this.onAddToFavorites,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(locationPickerProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 8.0,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          bottomPadding > 0 ? bottomPadding : 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Set Location",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.star_border, color: Colors.grey[600]),
                  tooltip: 'Add to Favorites',
                  onPressed: onAddToFavorites,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.isLoadingAddress
                        ? Text(
                            "Loading...",
                            key: const ValueKey('loading'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          )
                        : Text(
                            state.selectedDescription ??
                                "Move the map to select",
                            key: ValueKey(state.selectedDescription),
                            style: theme.textTheme.bodyLarge,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    state.selectedPoint != null && !state.isLoadingAddress
                    ? onConfirm
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Confirm Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
