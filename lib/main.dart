import 'package:app_links/app_links.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
// import 'package:simple_icons/simple_icons.dart';

import 'config.dart';

import 'library.dart';

/// Fill in this value with the subdomain and region found on your Nhost project page.
const nhostGithubSignInUrl = 'https://local.auth.nhost.run/v1/signin/provider/github';
const nhostGoogleSignInUrl = 'https://wlvuqvwubqqschjjpook.auth.eu-central-1.nhost.run/v1/signin/provider/google';

const signInSuccessHost = 'oauth.login.success';
const signInFailureHost = 'oauth.login.failure';

void main() {
  runApp(const OAuthExample());
}

class OAuthExample extends StatefulWidget {
  const OAuthExample({super.key});

  @override
  OAuthExampleState createState() => OAuthExampleState();
}

class OAuthExampleState extends State<OAuthExample> with ChangeNotifier {
  late NhostClient nhostClient;
  late AppLinks appLinks;
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

  handleAppLink() async {
    appLinks = AppLinks();
    final uri = await appLinks.getInitialAppLink();
    if (uri?.host == signInSuccessHost) {
      await nhostClient.auth.completeOAuthProviderSignIn(uri!);
    }
    await url_launcher.closeInAppWebView();
  }

  @override
  void initState() {
    super.initState();
// Create a new Nhost client using your project's subdomain and region.
    nhostClient = NhostClient(
      subdomain: Subdomain(
        subdomain: subdomain,
        region: region,
      ),
    );
    handleAppLink();
  }

  @override
  void dispose() {
    super.dispose();
    nhostClient.close();
  }

  @override
  Widget build(BuildContext context) {
    return NhostAuthProvider(
      auth: nhostClient.auth,
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedWidget = 0;

  Widget selectOne(int selected) {
    switch (selected) {
      case 0:
        return const GeneratorPage();
      case 1:
        return const FavoritesPage();
      case 2:
        return const OpenLibrarySearchWidget();
      default:
        throw UnimplementedError('no widget for slot $selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context)!;
    Widget page;
    switch (auth.authenticationState) {
      case AuthenticationState.signedIn:
        page = selectOne(selectedWidget);
        break;
      default:
        page = const ProviderSignInForm();
        break;
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
                      icon: Icon(Icons.book),
                      label: Text('Book'),
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
    var appState = context.watch<OAuthExampleState>();
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
    var appState = context.watch<OAuthExampleState>();
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

class ProviderSignInForm extends StatelessWidget {
  const ProviderSignInForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BigLoginCard(
          signInUrl: nhostGithubSignInUrl,
          iconData: SimpleIcons,
          name: 'GitHub',
        ),
        BigLoginCard(
          signInUrl: nhostGoogleSignInUrl,
          signInText: 'Authenticate with Google',
        ),
      ],
    );
  }
}

class BigLoginCard extends StatelessWidget {
  const BigLoginCard({
    super.key,
    required this.signInUrl,
    required this.name,
    required this.iconData,
  });

  final String signInUrl;
  final String name;
  final SimpleIcons icons;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium?.copyWith(color: theme.colorScheme.onPrimary)?.getTextStyle();
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              await url_launcher.launchUrl(Uri.parse(signInUrl));
            } on Exception {
              // Exceptions can occur due to weirdness with redirects
              debugPrint('exception occurred in launching $signInUrl');
            }
          },
          icon: Icon(iconData),
          label: Text(name),
        ),
      ),
    );
  }
}
