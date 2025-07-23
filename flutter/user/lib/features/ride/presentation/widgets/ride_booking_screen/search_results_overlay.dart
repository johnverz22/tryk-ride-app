import 'package:flutter/material.dart';
import 'package:user/features/ride/domain/entities/place_entity.dart';

class SearchResultsOverlay extends StatelessWidget {
  final List<PlaceSuggestionEntity> results;
  final bool isLoading;
  final void Function(PlaceSuggestionEntity) onSuggestionTap;

  const SearchResultsOverlay({
    Key? key,
    required this.results,
    required this.isLoading,
    required this.onSuggestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final suggestion = results[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(suggestion.description),
            onTap: () => onSuggestionTap(suggestion),
          );
        },
      ),
    );
  }
}
