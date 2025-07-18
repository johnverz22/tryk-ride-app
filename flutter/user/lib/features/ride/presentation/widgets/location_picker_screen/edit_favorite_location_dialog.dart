// lib/features/ride/presentation/widgets/location_picker_screen/edit_favorite_location_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/domain/entities/location_entity.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';

class EditFavoriteLocationDialog extends ConsumerStatefulWidget {
  final LocationEntity favoriteLocation;

  const EditFavoriteLocationDialog({super.key, required this.favoriteLocation});

  @override
  ConsumerState<EditFavoriteLocationDialog> createState() =>
      _EditFavoriteLocationDialogState();
}

class _EditFavoriteLocationDialogState
    extends ConsumerState<EditFavoriteLocationDialog> {
  late TextEditingController _nameController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.favoriteLocation.name);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
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

    final currentState = ref.read(locationPickerProvider);
    final newLatLng = currentState.selectedPoint;

    if (newLatLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get the current location.')),
        );
      }
      return;
    }

    await ref
        .read(locationPickerProvider.notifier)
        .updateFavoriteLocation(widget.favoriteLocation.id, name, newLatLng);

    final latestState = ref.read(locationPickerProvider);
    if (mounted) {
      if (latestState.errorMessage == null) {
        Navigator.pop(context); // Close dialog on success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              latestState.errorMessage ?? 'Failed to update location.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Favorite'),
        content: const Text(
          'Are you sure you want to delete this favorite location? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.pop(context); // Pop the edit dialog
      await ref
          .read(locationPickerProvider.notifier)
          .deleteFavoriteLocation(widget.favoriteLocation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationPickerState = ref.watch(locationPickerProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Edit Favorite', style: theme.textTheme.headlineSmall),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: _onDelete,
            tooltip: 'Delete Favorite',
          ),
        ],
      ),
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
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
