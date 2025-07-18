// lib/features/ride/presentation/widgets/location_picker_screen/add_favorite_location_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';

class AddFavoriteLocationDialog extends ConsumerStatefulWidget {
  const AddFavoriteLocationDialog({super.key});

  @override
  ConsumerState<AddFavoriteLocationDialog> createState() =>
      _AddFavoriteLocationDialogState();
}

class _AddFavoriteLocationDialogState
    extends ConsumerState<AddFavoriteLocationDialog> {
  late TextEditingController _nameController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Correctly initialize the controller's text ONCE in initState.
    // Reading the provider here is safe and efficient.
    final initialDescription = ref
        .read(locationPickerProvider)
        .selectedDescription;
    _nameController = TextEditingController(text: initialDescription);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Also select the text for quick editing if it was pre-filled.
      if (_nameController.text.isNotEmpty) {
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _nameController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a name for the location.'),
          ),
        );
      }
      return;
    }

    // Read the notifier and current state.
    final notifier = ref.read(locationPickerProvider.notifier);
    final currentState = ref.read(locationPickerProvider);

    // Ensure the selected point is still valid.
    if (currentState.selectedPoint == null) return;

    await notifier.addFavoriteLocation(name, currentState.selectedPoint!);

    // After awaiting, check the latest state for any errors.
    final latestState = ref.read(locationPickerProvider);
    if (mounted) {
      if (latestState.errorMessage == null) {
        Navigator.pop(context); // Close dialog on success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              latestState.errorMessage ?? 'Failed to save location.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationPickerState = ref.watch(locationPickerProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Text('Add Favorite', style: theme.textTheme.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Home, Work, Gym',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Location', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: theme.colorScheme.primary.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: locationPickerState.isLoadingAddress
                            ? Text(
                                'Loading address...',
                                key: const ValueKey('loading'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              )
                            : Text(
                                locationPickerState.selectedDescription ??
                                    'Address not found',
                                key: ValueKey(
                                  locationPickerState.selectedDescription,
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: !locationPickerState.isAddingOrEditing ? _onSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: locationPickerState.isAddingOrEditing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
