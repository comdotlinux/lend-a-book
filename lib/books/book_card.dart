import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lend_a_book/library.dart';
import 'package:logger/logger.dart';

import '../openlibrary/book.dart';
import 'image_carousel.dart';

const smallSpacing = 10.0;
const double cardWidth = 115;
const double widthConstraint = 450;

class BookCard extends StatelessWidget {
  BookCard({super.key, required this.searchResult});

  final _l = Logger();

  final SearchResultBook searchResult;

  @override
  Widget build(BuildContext context) {
    return ComponentDecoration(
      label: searchResult.title,
      tooltipMessage: 'The internal key is ${searchResult.key}',
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            // width: cardWidth,
            child: Card(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 5, 10),
                child: Column(
                  children: [
                    ExpandingCards(
                      items: searchResult.coverImageUrls, height: 50,
                    ),
/*                    Align(
                      child: CachedNetworkImage(
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        imageUrl: searchResult.coverImageUrls.isNotEmpty ? searchResult.coverImageUrls.first : 'http://via.placeholder.com/350x150',
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),*/
                    const Divider(),
                    Text('Published: ${searchResult.firstPublished}'),
                    const Divider(),
                    const Text('Publishers'),
                    const TitleList(publishers),
                    const Divider(),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.bottomLeft,
                      child: Text('Elevated'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComponentDecoration extends StatefulWidget {
  const ComponentDecoration({
    super.key,
    required this.label,
    required this.child,
    this.tooltipMessage = '',
  });

  final String label;
  final Widget child;
  final String? tooltipMessage;

  @override
  State<ComponentDecoration> createState() => _ComponentDecorationState();
}

class _ComponentDecorationState extends State<ComponentDecoration> {
  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: smallSpacing),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
                Tooltip(
                  message: widget.tooltipMessage,
                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 5.0), child: Icon(Icons.info_outline, size: 16)),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: widthConstraint),
              // Tapping within the a component card should request focus
              // for that component's children.
              child: Focus(
                focusNode: focusNode,
                canRequestFocus: true,
                child: GestureDetector(
                  onTapDown: (_) {
                    focusNode.requestFocus();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 20.0),
                      child: Center(
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleList extends StatelessWidget {
  final List<String> _inputs;

  const TitleList(this._inputs, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(1),
      children: _inputs
          .map((input) => [
                ListTile(
                  leading: CircleAvatar(child: Text(input.characters.first)),
                  title: Text(input),
                  trailing: const Icon(Icons.person_2),
                ),
                const Divider(height: 0)
              ])
          .flattened
          .toList(),
    );
  }
}
