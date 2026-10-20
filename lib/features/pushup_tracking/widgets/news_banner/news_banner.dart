import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/active_effects_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_state.dart';
import 'package:pushup_bro/features/pushup_tracking/model/news.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/news_banner/news_banner_item.dart';

class NewsBanner extends StatefulWidget {
  const NewsBanner({
    required this.newsVisible,
    super.key,
  });

  final bool newsVisible;

  @override
  State<NewsBanner> createState() => _NewsBannerState();
}

class _NewsBannerState extends State<NewsBanner>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  double factor = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant NewsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newsVisible == widget.newsVisible) {
      return;
    }

    if (widget.newsVisible) {
      unawaited(context.read<NewsCubit>().getNews());
      final news = context.read<NewsCubit>().state.news;
      for (final element in news) {
        final effect = element.type.correspondingEffect;
        if (effect != null) {
          context.read<ActiveEffectsCubit>().addEffect(effect);
        }
      }
      _animController.forward(from: 0);
    } else {
      _animController.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        top: 100,
        child: ScaleTransition(
          alignment: Alignment.topCenter,
          scale: _scaleAnimation,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 120,
              child: BlocBuilder<NewsCubit, NewsState>(
                builder: (context, state) => PageView.builder(
                  itemCount: state.news.length,
                  controller: _pageController,
                  itemBuilder: (context, index) => ListenableBuilder(
                    listenable: _pageController,
                    builder: (context, child) {
                      if (_pageController.position.hasContentDimensions) {
                        factor = 1 - (_pageController.page! - index).abs();
                      }

                      return NewsBannerItem(
                        factor: factor,
                        index: index,
                        news: state.news[index],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
