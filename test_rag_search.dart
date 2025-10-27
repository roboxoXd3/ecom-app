// Test file to verify RAG search functionality
// Run this in your Flutter app to test the new semantic search features

import 'package:flutter/material.dart';
import 'lib/features/data/services/product_search_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RAG Search Test', home: TestSearchScreen());
  }
}

class TestSearchScreen extends StatefulWidget {
  const TestSearchScreen({super.key});

  @override
  _TestSearchScreenState createState() => _TestSearchScreenState();
}

class _TestSearchScreenState extends State<TestSearchScreen> {
  final ProductSearchService _searchService = ProductSearchService();
  final TextEditingController _controller = TextEditingController();
  List<String> _results = [];
  bool _isLoading = false;

  Future<void> _testSearch(String query) async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      // Test semantic search
      final products = await _searchService.semanticSearch(
        query: query,
        limit: 5,
      );

      setState(() {
        _results =
            products
                .map((p) => '${p.name} - ${p.brand} (\$${p.price})')
                .toList();
      });
    } catch (e) {
      setState(() {
        _results = ['Error: $e'];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test RAG Search')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search Query',
                hintText: 'Try: "comfortable shoes for running"',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _testSearch(_controller.text),
                ),
              ),
              onSubmitted: _testSearch,
            ),
            SizedBox(height: 20),
            Text(
              'Test Queries:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              children:
                  [
                        'shoes for jogging',
                        'comfortable workout pants',
                        'eye protection glasses',
                        'fitness tracker',
                        'wireless audio',
                        'casual clothing',
                        'stylish accessories',
                      ]
                      .map(
                        (query) => Padding(
                          padding: EdgeInsets.all(4),
                          child: ElevatedButton(
                            child: Text(query),
                            onPressed: () {
                              _controller.text = query;
                              _testSearch(query);
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    return ListTile(title: Text(_results[index]));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
