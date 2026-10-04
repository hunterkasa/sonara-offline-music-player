import 'package:flutter/material.dart';

import '../../app/theme/theme_tokens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Songs, artists, albums or genres',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    ),
                ],
                elevation: const WidgetStatePropertyAll<double>(0.0),
                backgroundColor: WidgetStatePropertyAll<Color>(
                  theme.colorScheme.surfaceContainerHigh,
                ),
                shape: const WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
                ),
                onChanged: (val) {
                  setState(() {});
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: Text(
                'Browse All',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.s,
                crossAxisSpacing: AppSpacing.s,
                childAspectRatio: 1.8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final genres = [
                  ('Rock', Colors.deepOrange),
                  ('Pop', Colors.pinkAccent),
                  ('Hip-Hop', Colors.amber.shade800),
                  ('Classical', Colors.blueGrey),
                  ('Jazz', Colors.indigo),
                  ('Electronic', Colors.teal),
                ];
                final item = genres[index % genres.length];
                return Container(
                  decoration: BoxDecoration(
                    color: item.$2.withValues(alpha: 0.85),
                    borderRadius: AppRadii.cardRadius,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }, childCount: 6),
            ),
          ),
        ],
      ),
    );
  }
}
