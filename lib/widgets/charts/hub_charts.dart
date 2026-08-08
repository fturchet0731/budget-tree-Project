import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../models/check_in.dart';
import '../../services/reflection_stats.dart';
import '../../theme/app_dims.dart';
import '../../theme/app_tokens.dart';

/// Chart colours for Acorn's Hub.
///
/// **One chromatic series, everything else neutral furniture.** That is a
/// deliberate accessibility choice, not minimalism: the app's status trio
/// (`success` green, `warning` amber, `danger` red) is almost invisible under
/// simulated deuteranopia — green against amber measures an OKLab delta-E of
/// 0.3, and green against red 3.0, where 8 is the floor for two marks a reader
/// has to tell apart. Encoding outcome by hue would have made these charts
/// unreadable for red-green colourblind users.
///
/// So outcome is carried by **fill and shape** instead (how full a pip is, how
/// far a bar runs past its plan tick), always with a written label beside it,
/// and colour only reinforces. Status hues appear on *text* — where they sit
/// next to a word and an icon, never alone.
///
/// [series] is `Conifer.c600`, chosen because it is the one step that clears
/// the lightness band, the chroma floor and the 3:1 contrast minimum against
/// **both** the light card (3.34:1) and the dark card (4.42:1), so the charts
/// need no per-theme repaint.
class ChartColors {
  ChartColors._();

  static const series = Color(0xFF60961A);

  static Color track(AppTokens t) => t.canvasSoft;
  static Color grid(AppTokens t) => t.cardBorder;
  static Color ink(AppTokens t) => t.textSecondary;
  static Color faintInk(AppTokens t) => t.textTertiary;
}

// ── Consistency strip ───────────────────────────────────────────

/// One pip per resolved check-in, oldest on the left.
///
/// Fullness is the encoding: a whole pip means the user stayed on plan, a
/// part-filled one means they slipped, a hollow ring means they never answered.
/// Reading the row left to right shows a habit forming or fraying, which is the
/// single thing the hub exists to make visible.
class ConsistencyStrip extends StatelessWidget {
  final List<ConsistencyPoint> points;
  final double height;

  /// Show the four-state key underneath. Off inside the story slides, where
  /// Acorn explains the same thing in words.
  final bool showLegend;

  const ConsistencyStrip({
    super.key,
    required this.points,
    this.height = 34,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _PipPainter(points: points, tokens: t),
            ),
          ),
        ),
        if (showLegend) ...[
          const SizedBox(height: AppDims.s8),
          Wrap(
            spacing: AppDims.s12,
            runSpacing: 6,
            children: [
              _LegendPip(fill: 1.0, label: l.checkInOnTrack),
              _LegendPip(fill: 0.55, label: l.checkInSlipped),
              _LegendPip(fill: 0.25, label: l.checkInOffPlan),
              _LegendPip(fill: null, label: l.checkInMissed),
            ],
          ),
        ],
      ],
    );
  }
}

/// How full the pip for [point] is drawn. Null means an unanswered check-in,
/// which is a hollow ring rather than an empty fill.
double? _fillFor(ConsistencyPoint p) {
  if (p.missed) return null;
  switch (p.verdict) {
    case CheckInVerdict.onTrack:
      return 1.0;
    case CheckInVerdict.slipped:
      return 0.55;
    case CheckInVerdict.offPlan:
      return 0.25;
    case null:
      return 0.25;
  }
}

class _PipPainter extends CustomPainter {
  final List<ConsistencyPoint> points;
  final AppTokens tokens;

  const _PipPainter({required this.points, required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    // A 2px breathing gap between neighbours so a run of full pips still reads
    // as separate events rather than one bar.
    const gap = 6.0;
    final maxDiameter = math.min(size.height, 18.0);
    final slot = (size.width + gap) / points.length;
    final d = math.min(maxDiameter, math.max(6.0, slot - gap));
    final r = d / 2;
    final y = size.height / 2;

    for (var i = 0; i < points.length; i++) {
      final cx = slot * i + d / 2;
      if (cx + r > size.width) break;
      final centre = Offset(cx, y);
      final fill = _fillFor(points[i]);

      if (fill == null) {
        canvas.drawCircle(
          centre,
          r - 1,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ChartColors.faintInk(tokens),
        );
        continue;
      }

      // Track ring, then the filled core scaled by the verdict.
      canvas.drawCircle(centre, r, Paint()..color = ChartColors.track(tokens));
      canvas.drawCircle(
        centre,
        r * math.sqrt(fill),
        Paint()..color = ChartColors.series,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter old) =>
      old.points != points || old.tokens != tokens;
}

class _LegendPip extends StatelessWidget {
  final double? fill;
  final String label;
  const _LegendPip({required this.fill, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CustomPaint(
            painter: _PipPainter(
              points: [
                ConsistencyPoint(
                  at: DateTime(2000),
                  verdict: fill == null
                      ? null
                      : (fill == 1.0
                          ? CheckInVerdict.onTrack
                          : (fill! > 0.4
                              ? CheckInVerdict.slipped
                              : CheckInVerdict.offPlan)),
                  missed: fill == null,
                ),
              ],
              tokens: t,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: ChartColors.ink(t),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Trend line ──────────────────────────────────────────────────

/// A single series over time. No legend by design: with one line the card's
/// own title names it, and a legend box would just be furniture.
class TrendLine extends StatelessWidget {
  final List<double> values;

  /// Fixed scale bounds. Health is always 0 to 100; savings scale to their own
  /// maximum, which the caller supplies.
  final double minValue;
  final double? maxValue;
  final double height;

  const TrendLine({
    super.key,
    required this.values,
    this.minValue = 0,
    this.maxValue,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _TrendPainter(
            values: values,
            minValue: minValue,
            maxValue: maxValue,
            tokens: AppTokens.of(context),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final double minValue;
  final double? maxValue;
  final AppTokens tokens;

  const _TrendPainter({
    required this.values,
    required this.minValue,
    required this.maxValue,
    required this.tokens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 8.0;
    final top = pad;
    final bottom = size.height - pad;
    final lo = minValue;
    final hi = math.max(
      lo + 1,
      maxValue ?? values.reduce(math.max),
    );

    double yFor(double v) =>
        bottom - ((v - lo) / (hi - lo)).clamp(0.0, 1.0) * (bottom - top);

    // Recessive baseline only. No gridlines: at this size they'd out-weigh the
    // one line they're meant to support.
    canvas.drawLine(
      Offset(0, bottom),
      Offset(size.width, bottom),
      Paint()
        ..color = ChartColors.grid(tokens)
        ..strokeWidth = 1,
    );

    if (values.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, yFor(values.first)),
        5,
        Paint()..color = ChartColors.series,
      );
      return;
    }

    final step = size.width / (values.length - 1);
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(i * step, yFor(values[i])),
    ];

    // Soft area under the line, then the line itself at 2px.
    final area = Path()..moveTo(pts.first.dx, bottom);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(pts.last.dx, bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = ChartColors.series.withValues(alpha: 0.12),
    );

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = ChartColors.series,
    );

    // Only the latest point gets a marker, with a surface ring so it stays
    // legible where the line doubles back under it.
    canvas.drawCircle(pts.last, 5.5, Paint()..color = tokens.card);
    canvas.drawCircle(pts.last, 4, Paint()..color = ChartColors.series);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values ||
      old.minValue != minValue ||
      old.maxValue != maxValue ||
      old.tokens != tokens;
}

// ── Planned versus actual ───────────────────────────────────────

/// What each branch was planned to take, against what the user reported.
///
/// One bar per branch on a shared scale, with a tick marking the plan. A bar
/// that runs past its tick overspent, and the amount is written out beside it,
/// so the reading never depends on noticing a colour.
class PlannedVsActualBars extends StatelessWidget {
  final List<OverspendRow> rows;
  final int maxRows;

  const PlannedVsActualBars({
    super.key,
    required this.rows,
    this.maxRows = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final t = AppTokens.of(context);
    final shown = rows.take(maxRows).toList();
    // One scale across every row, or the bars cannot be compared to each other.
    final scale = shown
        .map((r) => math.max(r.planned, r.actual))
        .fold<double>(1, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDims.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: t.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDims.s8),
                    // The status word carries an icon and a number, so the
                    // colour on it is reinforcement and never the whole signal.
                    Icon(
                      row.isOver
                          ? Icons.arrow_upward
                          : Icons.check_circle_outline,
                      size: 13,
                      color: row.isOver ? t.danger : t.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      row.isOver
                          ? l.hubOverBy(
                              '\$${row.difference.abs().toStringAsFixed(0)}')
                          : l.hubWithinPlan,
                      style: GoogleFonts.nunito(
                        color: row.isOver ? t.danger : t.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 14,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BarPainter(
                      planned: row.planned,
                      actual: row.actual,
                      scale: scale,
                      tokens: t,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final double planned;
  final double actual;
  final double scale;
  final AppTokens tokens;

  const _BarPainter({
    required this.planned,
    required this.actual,
    required this.scale,
    required this.tokens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = const Radius.circular(4);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(full, radius),
      Paint()..color = ChartColors.track(tokens),
    );

    final w = (actual / scale).clamp(0.0, 1.0) * size.width;
    if (w > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, math.max(w, 4), size.height),
          radius,
        ),
        Paint()..color = ChartColors.series,
      );
    }

    // The plan tick, drawn over the fill with a surface-coloured gap either
    // side so it reads against both the bar and the track.
    final x = (planned / scale).clamp(0.0, 1.0) * size.width;
    canvas.drawRect(
      Rect.fromLTWH(x - 2, -1, 4, size.height + 2),
      Paint()..color = tokens.card,
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 1, -1, 2, size.height + 2),
      Paint()..color = ChartColors.ink(tokens),
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.planned != planned ||
      old.actual != actual ||
      old.scale != scale ||
      old.tokens != tokens;
}
