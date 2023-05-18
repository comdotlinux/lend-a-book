import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    setState(() {
      _isLoading = true;
    });
    Future.delayed(const Duration(seconds: 2), () async {
      final response = await http.get(Uri.parse('https://openlibrary.org/search.json?sort=new&limit=3&title=${_searchController.text.toLowerCase()}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          var booksAsJson = List<Map<String, dynamic>>.from(data['docs']);
          _searchResults = booksAsJson.map((b) => Book.fromJson(b)).toList();

          _isLoading = false;
        });
      } else {
        debugPrint('Failed to load search results');
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
