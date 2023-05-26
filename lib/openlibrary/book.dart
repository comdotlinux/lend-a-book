import 'package:collection/collection.dart';

import 'author.dart';

class SearchResultBook {
  String key;
  String type;
  String title;
  List<String> subjects;
  int firstPublished;
  List<String> publishers;
  List<Author> authors;
  List<String> isbns;
  Set<String> coverImageUrls = {};

  void addCoverUrl(String url) {
    coverImageUrls.add(url);
  }


  SearchResultBook.create({required this.key, required this.type, required this.title, required this.subjects, required this.firstPublished, required this.publishers, required this.authors, required this.isbns});

  factory SearchResultBook.fromJson(Map<String, dynamic> json) {
    var authorKeys = List<String>.from(json['author_key'] ?? []);
    var authorNames = List<String>.from(json['author_name'] ?? []);
    var authors = IterableZip([authorKeys, authorNames]).map((author) => Author.create(author.first, author.last)).toList();

    return SearchResultBook.create(
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