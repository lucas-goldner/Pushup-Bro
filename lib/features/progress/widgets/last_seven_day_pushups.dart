import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/extensions/datetime_ext.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';

class LastSevenDayPushups extends StatefulWidget {
  const LastSevenDayPushups({super.key});

  @override
  State<LastSevenDayPushups> createState() => _LineChartSample2State();
}

class _LineChartSample2State extends State<LastSevenDayPushups> {
  bool showTotal = false;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PushupSet>>(
        future: context.read<DBCubit>().getAllPushupSets(),
        builder: (context, snapshot) {
          final pushups = snapshot.data ?? [];

          return Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(
                  PBSpace.md,
                  PBSpace.lg,
                  PBSpace.xl,
                  PBSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(PBRadius.lg),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: PBSpace.md,
                        bottom: PBSpace.md,
                      ),
                      child: Text(
                        (showTotal
                                ? context.l10n.total
                                : context.l10n.lastSevenDays)
                            .toUpperCase(),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: LineChart(
                        showTotal
                            ? mainData(pushups)
                            : lastSevenDaysData(pushups),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PBSpace.xl),
              Row(
                children: [
                  Expanded(
                    child: PBButton(
                      showTotal
                          ? context.l10n.lastSevenDays
                          : context.l10n.total,
                      callback: () => setState(() => showTotal = !showTotal),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

  /// The line in the theme's secondary colour, fading out below.
  LineChartBarData _line(List<FlSpot> spots) {
    final color = context.colorScheme.secondary;

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: context.colorScheme.surface,
          strokeWidth: 3,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  /// Hairline horizontal grid and no frame.
  FlGridData get _grid => FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: context.colorScheme.outlineVariant,
          strokeWidth: 1,
        ),
      );

  /// Tooltips in the inverse surface, readable in both modes.
  LineTouchData get _touch => LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => context.colorScheme.inverseSurface,
          getTooltipItems: (spots) => [
            for (final spot in spots)
              LineTooltipItem(
                spot.y.toInt().toString(),
                context.textTheme.labelMedium!.copyWith(
                  color: context.colorScheme.onInverseSurface,
                ),
              ),
          ],
        ),
      );

  Widget bottomTitleWidgets(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) {
    final style = context.textTheme.bodySmall;

    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text('JAN', style: style);
      case 4:
        text = Text('APR', style: style);
      case 8:
        text = Text('AUG', style: style);
      case 12:
        text = Text('DEC', style: style);
      default:
        text = Text('', style: style);
    }

    return SideTitleWidget(
      meta: meta,
      child: text,
    );
  }

  Widget leftTitleWidgets(BuildContext context, double value, TitleMeta meta) {
    final style = context.textTheme.bodySmall;
    String text;
    switch (value.toInt()) {
      case 10:
        text = '10';
      case 25:
        text = '25';
      case 50:
        text = '50';
      case 75:
        text = '75';
      case 100:
        text = 'Over 100';
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  Widget lastSevenDaysBottomTitleWidgets(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) =>
      SideTitleWidget(
        meta: meta,
        child: Text(
          value.toInt().toString(),
          style: context.textTheme.bodySmall,
        ),
      );

  LineChartData mainData(List<PushupSet> pushups) => LineChartData(
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) => bottomTitleWidgets(
                context,
                value,
                meta,
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) => leftTitleWidgets(
                context,
                value,
                meta,
              ),
              reservedSize: 42,
            ),
          ),
        ),
        minX: 1,
        maxX: 12,
        minY: 0,
        maxY: pushups.monthWithMostPushups.pushups.toDouble() + 10,
        gridData: _grid,
        borderData: FlBorderData(show: false),
        lineTouchData: _touch,
        lineBarsData: [
          _line(
            pushups.stackedPerMonth
                .map(
                  (e) => FlSpot(
                    e.month.toDouble(),
                    e.pushups.toDouble(),
                  ),
                )
                .toList(),
          ),
        ],
      );

  LineChartData lastSevenDaysData(List<PushupSet> pushups) {
    final lastSevenDaysPushups = pushups.lastSevenDaysPushups;
    final lastSevenDays = DateTime.now().lastSevenDays;

    return LineChartData(
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) => lastSevenDaysBottomTitleWidgets(
              context,
              value,
              meta,
            ),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) => leftTitleWidgets(
              context,
              value,
              meta,
            ),
            reservedSize: 42,
          ),
        ),
      ),
      minX: lastSevenDays.first.day.toDouble(),
      maxX: lastSevenDays.last.day.toDouble(),
      minY: 0,
      maxY: 100,
      gridData: _grid,
      borderData: FlBorderData(show: false),
      lineTouchData: _touch,
      lineBarsData: [
        _line(
          lastSevenDaysPushups
              .map(
                (pushups) => FlSpot(
                  pushups.day.toDouble(),
                  pushups.pushups.toDouble(),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
