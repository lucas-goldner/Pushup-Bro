import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// A story line at the bottom of the screen: the speaker's avatar and name
/// tag over a card that types the text out. Tap to finish typing; tap again
/// to go on ([onNext]).
class DialogBox extends StatefulWidget {
  const DialogBox({
    required this.line,
    required this.onNext,
    this.trailing,
    super.key,
  });

  final Line line;
  final VoidCallback onNext;

  /// Shown instead of the "next" hint, e.g. a button after the last line.
  final Widget? trailing;

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typing;

  @override
  void initState() {
    super.initState();
    _typing = AnimationController(
      vsync: this,
      duration: _typingTime,
    )
      ..addListener(_blip)
      ..forward();
  }

  int _blipped = 0;

  /// A soft blip every few letters while the line types out.
  void _blip() {
    final length = widget.line.$2(S.current).length;
    final shown = (length * _typing.value).round();
    if (shown ~/ 3 > _blipped ~/ 3 && shown < length) {
      GameAudio.instance.play(Sfx.blip);
    }
    _blipped = shown;
  }

  @override
  void didUpdateWidget(covariant DialogBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) {
      _blipped = 0;
      _typing
        ..duration = _typingTime
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  /// About 22 ms a character, for the longest a line could be.
  Duration get _typingTime => Duration(
        milliseconds: 22 * widget.line.$2(S.current).length + 200,
      );

  void _tap() {
    if (_typing.isAnimating) {
      _typing.value = 1;
    } else {
      GameAudio.instance.play(Sfx.next);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final (speaker, lineText) = widget.line;
    final text = lineText(context.l10n);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 22),
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: speaker.color.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: background2.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _typing,
                  builder: (context, _) {
                    final shown = (text.length * _typing.value)
                        .round()
                        .clamp(0, text.length);

                    // The full text, with the part not yet typed hidden, so
                    // the box doesn't grow while it types.
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: text.substring(0, shown)),
                          TextSpan(
                            text: text.substring(shown),
                            style: const TextStyle(color: Colors.transparent),
                          ),
                        ],
                      ),
                      style: defaultTextStyle.copyWith(
                        color: background2,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: widget.trailing ??
                      AnimatedBuilder(
                        animation: _typing,
                        builder: (context, _) => AnimatedOpacity(
                          opacity: _typing.isCompleted ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            CarbonIcons.caret_right,
                            color: speaker.color,
                            size: 28,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            top: 0,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: speaker.color, width: 3),
                  ),
                  child: Text(
                    speaker.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: speaker.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    speaker.name(context.l10n),
                    style: buttonTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
