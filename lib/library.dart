import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lend_a_book/openlibrary/author.dart';

import 'books/book_card.dart';
import 'openlibrary/api_client.dart';
import 'openlibrary/book.dart';

class OpenLibrarySearchWidget extends StatefulWidget {
  const OpenLibrarySearchWidget({super.key});

  @override
  OpenLibrarySearchWidgetState createState() => OpenLibrarySearchWidgetState();
}

class OpenLibrarySearchWidgetState extends State<OpenLibrarySearchWidget> {
  final _apiClient = OpenLibraryApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultBook> _searchResults = [];
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
      var searchResults = await _apiClient.search(queryText);
      for (var result in searchResults) {
        final book = await _apiClient.book(result.key);
        var covers = await _apiClient.coverImages(book);
        covers.forEach(result.addCoverUrl);
      }
      setState(() {
        _searchResults = searchResults;

        _isLoading = false;
      });
    }

    );
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
          return BookCard(searchResult: result);
        },
      ),
    );
  }
}



const String jsonString = r'''{"description": "El libro de", "title": "Sapiens", "key": "/works/OL17075811W", "authors": [{"author": {"key": "/authors/OL3778242A"}, "type": {"key": "/type/author_role"}}, {"author": {"key": "/authors/OL8654786A"}, "type": {"key": "/type/author_role"}}, {"author": {"key": "/authors/OL8598815A"}, "type": {"key": "/type/author_role"}}, {"author": {"key": "/authors/OL3145199A"}, "type": {"key": "/type/author_role"}}], "type": {"key": "/type/work"}, "subjects": ["Cronolog\u00eda hist\u00f3rica", "Technology and civilization", "Tecnolog\u00eda y civilizaci\u00f3n", "Human beings", "Historical Chronology", "Historia universal", "Historia", "Civilization", "Hombre", "World history", "History", "Non-Fiction", "Science", "SCIENCE / Life Sciences / General", "SCIENCE / General", "SCIENCE / Life Sciences / Evolution", "Weltgeschichte", "Civilization, history", "Chronology, historical", "Chronologie historique", "Technologie et civilisation", "Histoire universelle", "Histoire", "Humans", "Civilisation", "Homme", "nyt:combined-print-and-e-book-nonfiction=2015-03-01", "New York Times bestseller", "Life Sciences", "Evolution", "General", "Menschheit", "Humanit\u00e9", "M\u00e4nniskan", "Fysisk antropologi", "Human", "Sapiens", "nyt:paperback-nonfiction=2018-06-03", "Comics & graphic novels, adaptations", "Zivilisation", "Society", "Psychology", "Economic history", "Cognition and culture"], "covers": [7387235, 8117573, 7914162, 8202297, 8203967, 8315361, 10254953, 10456630, 10492831, 10540490, 9367956, 11237094, 7349454, 10479543, 9031603, 12130527, 12369635, 12531613], "links": [{"title": "The Guardian review", "url": "https://www.theguardian.com/books/2014/sep/11/sapiens-brief-history-humankind-yuval-noah-harari-review", "type": {"key": "/type/link"}}, {"title": "Whitby Public Library", "url": "https://whitby.overdrive.com/media/1690806", "type": {"key": "/type/link"}}, {"url": "https://play.google.com/store/books/details/Sapiens_A_Brief_History_of_Humankind?id=Y41zAwAAQBAJ", "title": "Google Play Books", "type": {"key": "/type/link"}}, {"url": "https://www.polirom.ro/web/polirom/carti/-/carte/6444", "title": "Sapiens: Scurt\u0103 istorie a omenirii (saitul editurii Polirom)", "type": {"key": "/type/link"}}, {"url": "https://archive.org/details/sapiens-a-brief-history-of-humankind-urdu-omer-bangash", "title": "\u0622\u062f\u0645\u06cc: \u0628\u0646\u06cc \u0646\u0648\u0639 \u0627\u0646\u0633\u0627\u0646 \u06a9\u06cc \u0645\u062e\u062a\u0635\u0631 \u062a\u0627\u0631\u06cc\u062e", "type": {"key": "/type/link"}}], "subject_places": ["America", "Australia", "India"], "subject_times": ["100", "000 years ago"], "subtitle": "A Brief History of Humankind", "latest_revision": 20, "revision": 20, "created": {"type": "/type/datetime", "value": "2014-11-27T11:53:56.848815"}, "last_modified": {"type": "/type/datetime", "value": "2023-03-08T05:04:26.827607"}}''';
const subjects = ["Cronolog\u00eda hist\u00f3rica", "Technology and civilization", "Tecnolog\u00eda y civilizaci\u00f3n", "Human beings", "Historical Chronology", "Historia universal", "Historia", "Civilization", "Hombre", "World history", "History", "Non-Fiction", "Science", "SCIENCE / Life Sciences / General", "SCIENCE / General", "SCIENCE / Life Sciences / Evolution", "Weltgeschichte", "Civilization, history", "Chronology, historical", "Chronologie historique", "Technologie et civilisation", "Histoire universelle", "Histoire", "Humans", "Civilisation", "Homme", "nyt:combined-print-and-e-book-nonfiction=2015-03-01", "New York Times bestseller", "Life Sciences", "Evolution", "General", "Menschheit", "Humanit\u00e9", "M\u00e4nniskan", "Fysisk antropologi", "Human", "Sapiens", "nyt:paperback-nonfiction=2018-06-03", "Comics & graphic novels, adaptations", "Zivilisation", "Society", "Psychology", "Economic history", "Cognition and culture"];
const publishers = ["HarperCollins Publishers", "Albin Michel", "Deutsche Verlags-Anstalt", "Editura Polirom", "Vintage", "Harper", "Harper Perennial", "Penguin Random House", "Debate", "Blackstone Pub", "RANDOM HOUSE INDIA", "Tantor Audio", "Harpercollins", "Wydawnictwo Naukowe PWN", "Self-Published", "Dom Wydawniczy PWN", "Penguin Random House Grupo Editorial (Debate)", "Bompiani", "Harvill Secker", "Vintage Books", "Pantheon", "Signal", "DVA Dt.Verlags-Anstalt", "L&PM", "Sindbad", "Kolektif Kitap", "Pantheon Verlag"];
var authors = [Author.create("OL3778242A", "Yuval Noah Harari"), Author.create("OL8654786A", "Giuseppe Bernardi"), Author.create("OL8598815A", "David Vandermeulen"), Author.create("OL3145199A", "Daniel Casanave")];
const isbns = ["9781846558238","6559213013","9788845296499","6055029359","9781846558245","9780771038501","0099590085","9783421045959","2226257012","9786559213016","8499924212","1846558247","8525432180","9780063051331","0063051338","9788499924212","9788377059968","8418006811","9788525432186","8377059967","4309226728","430922671X","9734668463","9788934972464","9784309226712","9784309226729","6055029731","9781784873646","9780771038518","9789734668465","0771038518","0062316095","9780062316097","9786055029357","9734648888","1716994985","9788418006814","9781494556907","9781538456590","342104595X","8499926223","9789734648887","9734668471","144819069X","9781716994982","9789734668472","1494556901","9780063055087","9588806836","5905891648","0063055082","9781448190690","8845296490","9789537213657","9782226257017","8934972467","1538456591","077103850X","1784873640","9788499926223","9783570552698","9786055029739","0062316117","3570552691","9780099590088","1846558239","953721365X","9780062316110","9789588806839","9785905891649"];
var result = SearchResultBook.create(key: "/works/OL17075811W", type: "/type/author_role", title: "Sapiens", subjects: subjects, firstPublished: 2001, publishers: publishers, authors: authors, isbns: isbns);
class StaticOpenLibrarySearchWidget extends StatelessWidget {
  const StaticOpenLibrarySearchWidget({super.key});
  @override
  Widget build(BuildContext context) {
    result.addCoverUrl("https://covers.openlibrary.org/b/id/7387235-M.jpg");
    return Scaffold(body: BookCard(searchResult: result));
  }
}

