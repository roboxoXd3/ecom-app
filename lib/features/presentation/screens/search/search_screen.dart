import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/search_controller.dart' as app;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final app.SearchController _searchCtrl = Get.find<app.SearchController>();
  final RxBool _isSearching = false.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      _searchCtrl.searchProducts(query);
      Get.toNamed('/search-results', arguments: query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
            suffixIcon: Obx(
              () =>
                  _isSearching.value
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchCtrl.suggestions.clear();
                          _isSearching.value = false;
                        },
                      )
                      : const Icon(Icons.search),
            ),
          ),
          onChanged: (value) {
            _isSearching.value = value.isNotEmpty;
            _searchCtrl.getSuggestions(value);
          },
          onSubmitted: _handleSearch,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
      body: Obx(
        () =>
            _searchCtrl.suggestions.isEmpty
                ? _buildRecentSearches()
                : _buildSuggestions(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_searchCtrl.recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () => _searchCtrl.clearRecentSearches(),
                  child: const Text('Clear All'),
                ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => ListView.builder(
              itemCount: _searchCtrl.recentSearches.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_searchCtrl.recentSearches[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _searchCtrl.recentSearches.removeAt(index),
                  ),
                  onTap: () => _handleSearch(_searchCtrl.recentSearches[index]),
                );
              },
            ),
          ),
        ),
        // Popular searches section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Popular Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'iPhone',
                      'Headphones',
                      'Nike',
                      'Samsung',
                      'Watch',
                    ].map((tag) => _buildSearchTag(tag)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      itemCount: _searchCtrl.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _searchCtrl.suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestion),
          onTap: () => _handleSearch(suggestion),
        );
      },
    );
  }

  Widget _buildSearchTag(String tag) {
    return InkWell(
      onTap: () => _handleSearch(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(tag, style: TextStyle(color: AppTheme.primaryColor)),
      ),
    );
  }
}
