import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class OpenLibrarySearchWidget extends StatefulWidget {
  const OpenLibrarySearchWidget({super.key});

  @override
  OpenLibrarySearchWidgetState createState() => OpenLibrarySearchWidgetState();
}

class OpenLibrarySearchWidgetState extends State<OpenLibrarySearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchResults = [];
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty || _searchController.text.length < 3) {
      return;
    }
    Future.delayed(const Duration(seconds: 2), () async {
      var queryText = _searchController.text;
      if (queryText.isEmpty || queryText.length < 3) {
        debugPrint('Skipping search using query $queryText');
        return;
      }
      setState(() {
        _isLoading = true;
      });
      final searchResponse = await DefaultCacheManager().getSingleFile('https://openlibrary.org/search.json?limit=3&title=$queryText&mode=everything');
      if (searchResponse.existsSync()) {
        final data = json.decode(await searchResponse.readAsString());
        var booksAsJson = List<Map<String, dynamic>>.from(data['docs']);
        var searchResults = booksAsJson.map((b) => Book.fromJson(b)).toList();
        for (var result in searchResults) {
          var singleBookInfoUri = 'https://openlibrary.org/${result.key}.json';
          var singleBookInfoResponse = await DefaultCacheManager().getSingleFile(singleBookInfoUri);
          if (singleBookInfoResponse.existsSync()) {
            debugPrint('single book response : ${await singleBookInfoResponse.readAsString()}');
            final singleBookInfoResponseData = json.decode(await singleBookInfoResponse.readAsString());
            // var covers = await http.get(Uri.parse('https://covers.openlibrary.org/b/id/240727-S.jpg'));
            var coverIds = List<int>.from(singleBookInfoResponseData['covers'] ?? []);
            coverIds.map((c) => 'https://covers.openlibrary.org/b/id/$c-M.jpg').forEach((coverUrl) { result.addCoverUrl(coverUrl); });
            debugPrint('cover urls : ${result.coverImageUrls}');
          } else {
            debugPrint('$singleBookInfoResponse does not exist when getting book covers from $singleBookInfoUri');
          }
        }

        setState(() {
          _searchResults = searchResults;

          _isLoading = false;
        });
      } else {
        debugPrint('Failed to load search results, got $searchResponse');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // colors: [Colors.deepPurple, Colors.purple.shade300],
              colors: [theme.colorScheme.secondary, theme.colorScheme.secondary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: theme.primaryColorLight),
          cursorColor: theme.primaryColorLight,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: theme.primaryColorLight),
            border: InputBorder.none,
          ),
        ),
      ),
      // AppBar(title: const Text('OpenLibrary Book Search'),),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? const Text('No Results')
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      title: Text(result.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          CachedNetworkImage(
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            imageUrl: result.coverImageUrls.isNotEmpty ? result.coverImageUrls.first : 'http://via.placeholder.com/350x150',
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                          const SizedBox(height: 4),
                          Text('Author: ${result.authors.map((a) => a.name).join(', ')}'),
                          const SizedBox(height: 4),
                          Text('Published: ${result.firstPublished}'),
                          const SizedBox(height: 4),
                          Text('Publisher: ${result.publishers.join(', ')}'),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
    );
  }
}

class Book {
  String key;
  String type;
  String title;
  List<String> subjects;
  int firstPublished;
  List<String> publishers;
  List<Author> authors;
  List<String> isbns;
  List<String> coverImageUrls = [];

  void addCoverUrl(String url) {
    coverImageUrls.add(url);
  }


  Book.create({required this.key, required this.type, required this.title, required this.subjects, required this.firstPublished, required this.publishers, required this.authors, required this.isbns});

  factory Book.fromJson(Map<String, dynamic> json) {
    var authorKeys = List<String>.from(json['author_key'] ?? []);
    var authorNames = List<String>.from(json['author_name'] ?? []);
    var authors = IterableZip([authorKeys, authorNames]).map((author) => Author.create(author.first, author.last)).toList();

    return Book.create(
      key: json['key'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      subjects: List<String>.from(json['subject'] ?? []),
      firstPublished: json['first_publish_year'] as int,
      publishers: List<String>.from(json['publisher'] ?? []),
      authors: authors,
      isbns: List<String>.from(json['isbn'] ?? []),
    );
  }
}

class Author {
  String key;
  String name;

  Author.create(this.key, this.name);
}

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(color: theme.colorScheme.onPrimary);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          book.title,
          style: style,
        ),
      ),
    );
  }
}
