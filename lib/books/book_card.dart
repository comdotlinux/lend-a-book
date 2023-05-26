import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lend_a_book/library.dart';
import 'package:logger/logger.dart';

import '../openlibrary/book.dart';

const smallSpacing = 10.0;
const double cardWidth = 1000;
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
        alignment: WrapAlignment.spaceEvenly,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Card(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 5, 10),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextCard('${searchResult.title} (first published: ${searchResult.firstPublished})'),
                    ),
                    const Divider(),
                    MultipleImageCarousel(searchResult.coverImageUrls.toList()),
                    const Divider(),
                    const Text('Publishers'),
                    const TitleList(publishers),
                    const Divider(),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            action: SnackBarAction(
                              label: 'TODO',
                              onPressed: () {
                                // Code to execute.
                              },
                            ),
                            content: const Text('Reserve / Borrow'),
                            duration: const Duration(seconds: 5),
                            width: 280.0,
                            // Width of the SnackBar.
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, // Inner padding for SnackBar content.
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.bottomLeft,
                      child: Text('Some More things like authors isbn e.t.c.'),
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
              constraints: BoxConstraints.tightFor(width: (MediaQuery.of(context).size.width * 0.5)),
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
    return SizedBox(
      height: 100,
      child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(1),
          itemCount: _inputs.length,
          itemBuilder: (context, index) {
            final item = _inputs[index % _inputs.length];
            return ListTile(
              leading: CircleAvatar(child: Text(item.characters.first)),
              title: Text(item),
              trailing: const Icon(Icons.person_2),
            );
          }),
    );
  }
}

class MultipleImageCarousel extends StatelessWidget {
  final List<String> _images;

  const MultipleImageCarousel(this._images, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: CarouselSlider.builder(
        options: CarouselOptions(aspectRatio: 2.0, enlargeCenterPage: true, viewportFraction: 1, autoPlay: _images.length > 2, enableInfiniteScroll: false),
        itemCount: (_images.length / 2).round(),
        itemBuilder: (context, index, realIdx) {
          final int first = index * 2;
          final int second = first + 1;
          return Row(
            children: [first, second].map((idx) {
              return Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  // child: Image.network(_images[idx], fit: BoxFit.cover),
                  child: CachedNetworkImage(
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    imageUrl: _images[idx],
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class TextCard extends StatelessWidget {
  final String _text;

  const TextCard(
    this._text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.headlineSmall!.copyWith(color: theme.colorScheme.onSecondary);
    return Card(
      color: theme.colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          _text,
          style: style,
        ),
      ),
    );
  }
}

class ToDoSnackBar extends StatelessWidget {
  final Set<String> _texts;

  const ToDoSnackBar(this._texts, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Show Snackbar'),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            action: SnackBarAction(
              label: 'Action',
              onPressed: () {
                // Code to execute.
              },
            ),
            content: const Text('Awesome SnackBar!'),
            duration: const Duration(milliseconds: 1500),
            width: 280.0,
            // Width of the SnackBar.
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0, // Inner padding for SnackBar content.
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        );
      },
    );
  }
}
