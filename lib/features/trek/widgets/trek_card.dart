import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/trek/trek_map_page.dart';

const _green = Color(0xFF1F5A3C);
const _lime = Color(0xFF7DD957);

/// The way into the Jungle Trek from the jungle: a full card once today's
/// quest is done, a slim bar before.
class TrekCard extends StatelessWidget {
  const TrekCard({
    required this.trek,
    required this.big,
    required this.onPlay,
    super.key,
  });

  final TrekProgress trek;
  final bool big;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stage = currentStage(trek);
    final progress = l.trekStageNumber(stage.number);

    if (!big) {
      return Material(
        color: _green,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPlay,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                const Text('🦎', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l.trekTitle} · $progress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        buttonTextStyle.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  l.trekLevel(trek.level),
                  style: buttonTextStyle.copyWith(
                    color: _lime,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(CarbonIcons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        alignment: Alignment.bottomCenter,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D4F), _green],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🦎', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.trekTitle,
                        style: pageTitleTextStyle.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      Text(
                        '${l.trekLevel(trek.level)} · $progress',
                        style: buttonTextStyle.copyWith(
                          color: _lime,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.trekTagline,
              style: defaultTextStyle.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: PillButton(
                label: l.trekPlay,
                icon: CarbonIcons.play_filled_alt,
                color: const Color(0xFFE5534B),
                onPressed: onPlay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
