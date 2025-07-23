import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user/features/ride/domain/entities/location_entity.dart';
import 'package:user/features/ride/presentation/providers/location_picker_provider.dart';

class FavoritesCarousel extends ConsumerWidget {
  final void Function(LocationEntity) onFavoriteTap;
  final void Function(LocationEntity) onEditTap;

  const FavoritesCarousel({
    Key? key,
    required this.onFavoriteTap,
    required this.onEditTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(
      locationPickerProvider.select((state) => state.favoriteLocations),
    );

    return favsAsync.when(
      data: (favs) {
        if (favs.isEmpty) return const SizedBox(height: 10);
        return SizedBox(
          height: 85,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            scrollDirection: Axis.horizontal,
            itemCount: favs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final fav = favs[index];
              return SizedBox(
                width: 150,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () => onFavoriteTap(fav),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                fav.icon,
                                size: 22,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              InkWell(
                                onTap: () => onEditTap(fav),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.edit_outlined, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            fav.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 85,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(
        height: 85,
        child: Center(child: Text("Can't load favorites")),
      ),
    );
  }
}
