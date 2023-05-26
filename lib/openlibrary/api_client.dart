import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'book.dart';

const openLibraryApiBaseUrl = 'https://openlibrary.org';

// TODO: refactor this to be able to use something else other than DefaultCacheManager
/// This queries the API and returns the book results, as well as caching it somewhere
class OpenLibraryApiClient {
  final _l = Logger();

  Future<DefaultCacheManager> _client() async => DefaultCacheManager();

  Future<List<SearchResultBook>> search(String searchQuery, {int numResults = 3}) async {
    var encodedUrl = Uri.encodeFull('$openLibraryApiBaseUrl/search.json?limit=$numResults&title=$searchQuery&mode=everything');
    try {
      final client = await _client();
      final response = await client.getSingleFile(encodedUrl);
      if (await response.exists()) {
        final data = json.decode(await response.readAsString());
        var jsonArray = List<Map<String, dynamic>>.from(data['docs']);
        return jsonArray.map((b) => SearchResultBook.fromJson(b)).toList();
      }
    } on Exception catch (e) {
      _l.e('Exception in searching using Url $encodedUrl', e);
    }
    return List.empty();
  }

  // TODO: Map to object
  Future<dynamic> book(String key) async {
    var encodedUrl = Uri.encodeFull('$openLibraryApiBaseUrl$key.json');
    try {
      final client = await _client();
      final response = await client.getSingleFile(encodedUrl);
      if (await response.exists()) {
        var responseJson = json.decode(await response.readAsString());
        _l.d('Response Json $responseJson for url $encodedUrl');
        return responseJson;
      }
    } on Exception catch (e) {
      _l.e('Exception in getting a book using Url $encodedUrl', e);
    }
  }

  //TODO: use book object or another parameter
  Future<List<String>> coverImages(dynamic book, {CoverImageSize size = CoverImageSize.M}) async {
    var coverIds = List<int>.from(book['covers'] ?? []);
    var coverImageUrls = coverIds.map((c) => 'https://covers.openlibrary.org/b/id/$c-${size.name}.jpg').toList();
    _l.d('coverImageUrls $coverImageUrls');
    return coverImageUrls;
  }
}

enum CoverImageSize { S, M, L }
