import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CarouselImage {
  CarouselImage(this.title, this.subtitle, this.image, this.color, this.icon);


  String title;
  String subtitle;
  String image;
  Color color; // const Color(0xFFED5565),
  IconData icon = Icons.image;

  factory CarouselImage.create({required String title, required String subtitle, required String image, required Color color, IconData icon = Icons.image }) {
    return CarouselImage(title, subtitle, image, color, icon);
  }

}

final List<CarouselImage> items = [
  CarouselImage.create(title: 'Blonkisoaz', subtitle: 'Omuke trughte a otufta', image: 'https://66.media.tumblr.com/6fb397d822f4f9f4596dff2085b18f2e/tumblr_nzsvb4p6xS1qho82wo1_1280.jpg', color: const Color(0xFFED5565), icon: Icons.directions_walk),
  CarouselImage.create(title: 'Oretemauw', subtitle: 'Omuke trughte a otufta', image: 'https://66.media.tumblr.com/8b69cdde47aa952e4176b4200052abf4/tumblr_o51p7mFFF21qho82wo1_1280.jpg', color: const Color(0xFFFC6E51), icon: Icons.ac_unit),
  CarouselImage.create(title: 'Iteresuselle', subtitle: 'Omuke trughte a otufta', image: 'https://66.media.tumblr.com/5af3f8303456e376ceda1517553ba786/tumblr_o4986gakjh1qho82wo1_1280.jpg', color: const Color(0xFFFFCE54), icon: Icons.park),
  CarouselImage.create(title: 'Idiefe', subtitle: 'Omuke trughte a otufta', image: 'https://66.media.tumblr.com/5516a22e0cdacaa85311ec3f8fd1e9ef/tumblr_o45jwvdsL11qho82wo1_1280.jpg', color: const Color(0xFF2ECC71), icon: Icons.water_drop),
  CarouselImage.create(title: 'Inatethi', subtitle: 'Omuke trughte a otufta', image: 'https://66.media.tumblr.com/f19901f50b79604839ca761cd6d74748/tumblr_o65rohhkQL1qho82wo1_1280.jpg', color: const Color(0xFF5D9CEC), icon: Icons.sunny),
];

class Carousel extends StatelessWidget {
  final List<CarouselImage> _items;
  const Carousel(this._items, {super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: TextButton(
              onPressed: () {
                // launch a new page with url on web
                // launchUrlString('https://github.com/BirjuVachhani/expanding_flex_cards');
                print('---');
              },
              child: const Text('View on Github'),
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: ExpandingCards(
                height: 150,
                items: _items,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: TextButton(
              onPressed: () {
                // launch a new page with url on web
                // launchUrlString('https://victorofvalencia-blog.tumblr.com/');
                print('---');
              },
              child: const Text('Photos from Victor of Valencia on tumblr'),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandingCards extends StatefulWidget {
  final double height;
  final List<CarouselImage> items;

  const ExpandingCards({
    super.key,
    required this.height,
    required this.items,
  });

  @override
  State<ExpandingCards> createState() => _ExpandingCardsState();
}

class _ExpandingCardsState extends State<ExpandingCards> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        itemCount: widget.items.length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 56),
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          final item = widget.items[index % widget.items.length];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AnimatedCardItem(
              key: ValueKey(index),
              title: item.title,
              subtitle: item.subtitle,
              image: item.image,
              icon: item.icon,
              iconColor: item.color,
              isExpanded: _selectedIndex == index,
              animation: _controller,
              onTap: () => onExpand(_selectedIndex == index ? -1 : index),
            ),
          );
        },
      ),
    );
  }

  void onExpand(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedCardItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final Animation<double> animation;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color iconColor;

  const AnimatedCardItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.animation,
    required this.isExpanded,
    required this.onTap,
    required this.iconColor,
  });

  @override
  State<AnimatedCardItem> createState() => _AnimatedCardItemState();
}

class _AnimatedCardItemState extends State<AnimatedCardItem> {
  bool shouldRect = false;

  @override
  void didUpdateWidget(covariant AnimatedCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      shouldRect = true;
    } else {
      shouldRect = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double collapsedWidth = 70;
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            double value = shouldRect
                ? widget.isExpanded
                ? widget.animation.value
                : 1 - widget.animation.value
                : widget.isExpanded
                ? 1
                : 0;

            final double animValue = widget.isExpanded
                ? const Interval(0, 0.5, curve: Curves.fastOutSlowIn)
                .transform(value)
                : Interval(0.5, 1, curve: Curves.fastOutSlowIn.flipped)
                .transform(value);

            final imageScaleValue = widget.isExpanded
                ? const Interval(0.2, 1, curve: Curves.easeOut).transform(value)
                : const Interval(0.8, 1, curve: Curves.easeOut)
                .transform(value);

            final titleValue = widget.isExpanded
                ? const Interval(0.2, 0.8, curve: Curves.easeOut)
                .transform(value)
                : const Interval(0.2, 0.8, curve: Curves.easeOut)
                .transform(value);

            final subtitleValue = widget.isExpanded
                ? const Interval(0.4, 0.8, curve: Curves.easeOut)
                .transform(value)
                : const Interval(0.4, 0.8, curve: Curves.easeOut)
                .transform(value);

            return Transform.scale(
              scale: 1 + animValue * 0.02,
              child: Container(
                width: collapsedWidth + animValue * (600 - collapsedWidth),
                height: 400 + (animValue * 20),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .cardColor,
                  borderRadius: BorderRadius.circular(collapsedWidth / 2),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 1.2 - imageScaleValue * 0.03,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(widget.image),
                              fit: BoxFit.cover,
                            ),
                          ),
                          foregroundDecoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0),
                                Colors.black.withOpacity(1),
                              ],
                              stops: const [0.7, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 + animValue * 10,
                          vertical: 10 + animValue * 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(
                                dimension: 50,
                                child: Center(
                                  child: Icon(
                                    widget.icon,
                                    color: widget.iconColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.isExpanded)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Opacity(
                                        opacity: titleValue,
                                        child: Transform.translate(
                                          offset: Offset(
                                            20 * (1 - titleValue),
                                            0,
                                          ),
                                          child: Text(
                                            widget.title,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // const SizedBox(height: 2),
                                      Opacity(
                                        opacity: subtitleValue,
                                        child: Transform.translate(
                                          offset: Offset(
                                            20 * (1 - subtitleValue),
                                            0,
                                          ),
                                          child: Text(
                                            widget.subtitle,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}