import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'library.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Book Love',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>{};

  void toggleFavourite(WordPair wordPair) {
    if (favorites.contains(wordPair)) {
      favorites.remove(wordPair);
    } else {
      favorites.add(wordPair);
    }
    debugPrint("favorites $favorites");
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedWidget = 3;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedWidget) {
      case 0:
        page = const GeneratorPage();
        break;
      case 1:
        page = const FavoritesPage();
        break;
      case 2:
        page = const OpenLibrarySearchWidget();
        break;
      case 3:
        page = const StaticOpenLibrarySearchWidget();
        break;
      default:
        throw UnimplementedError('no widget for $selectedWidget');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                  extended: constraints.maxWidth > 600,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      label: Text('Book Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.book),
                      label: Text('Static Book'),
                    ),
                  ],
                  selectedIndex: selectedWidget,
                  onDestinationSelected: (value) {
                    debugPrint('Selected Index Changed to $value');
                    setState(() {
                      selectedWidget = value;
                    });
                  }),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavourite(appState.current);
                  },
                  icon: Icon(icon),
                  label: const Text(
                    'Like',
                  )),
              const SizedBox(
                width: 60,
              ),
              ElevatedButton.icon(
                onPressed: appState.getNext,
                icon: const Icon(Icons.navigate_next),
                label: const Text('Next'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(color: theme.colorScheme.onPrimary);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    var secondaryStyle = theme.textTheme.displayMedium!.copyWith(color: theme.colorScheme.onSecondary);
    var tertiaryStyle = theme.textTheme.displayMedium!.copyWith(color: theme.colorScheme.onTertiary);
    if (appState.favorites.isEmpty) {
      return Center(
        child: Card(
          color: theme.colorScheme.secondary,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No favorites yet.',
              style: secondaryStyle,
            ),
          ),
        ),
      );
    }
    return ListView(
      children: [
        Card(
          color: theme.colorScheme.tertiary,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'You have ${appState.favorites.length} favourites',
              style: tertiaryStyle,
            ),
          ),
        ),
        for (var fav in appState.favorites)
          Card(
            color: theme.colorScheme.secondary,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(
                  fav.asLowerCase,
                  style: secondaryStyle,
                ),
                trailing: ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavourite(fav);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
