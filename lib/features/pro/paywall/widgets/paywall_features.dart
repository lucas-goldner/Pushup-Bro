import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';

/// What Pro opens, as chips in two columns; the one on the stage glows.
class PaywallFeatures extends StatelessWidget {
  const PaywallFeatures({
    required this.current,
    required this.onSelected,
    super.key,
  });

  final ProFeature current;
  final ValueChanged<ProFeature> onSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    const features = ProFeature.values;
    for (var i = 0; i < features.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: PBSpace.sm));
      rows.add(
        Row(
          children: [
            for (final (j, feature) in features.skip(i).take(2).indexed) ...[
              if (j > 0) const SizedBox(width: PBSpace.sm),
              Expanded(
                child: _FeatureChip(
                  feature: feature,
                  selected: feature == current,
                  onTap: () => onSelected(feature),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(children: rows);
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final ProFeature feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = feature.color(context);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    context.tint(scheme.secondary),
                    scheme.surface,
                  )
                : scheme.surface,
            borderRadius: BorderRadius.circular(PBRadius.md),
            boxShadow: selected
                ? [BoxShadow(color: scheme.secondary, spreadRadius: 2)]
                : context.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(context.tint(color), scheme.surface),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(feature.icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              // Long labels shrink to fit rather than being cut off.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    feature.label(context),
                    maxLines: 1,
                    style:
                        context.textTheme.labelMedium?.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
