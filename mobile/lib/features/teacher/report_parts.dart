import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../data/repository.dart';
import '../../design_system/design_system.dart';

DSProgressBarTone toneFor(String kind) => kind == 'pre_test'
    ? DSProgressBarTone.blue
    : kind == 'post_test'
        ? DSProgressBarTone.teal
        : DSProgressBarTone.sun;

String csvCell(Object? v) {
  final raw = '${v ?? ''}';
  // Neutralize formula injection — cells starting with = + - @ execute as
  // spreadsheet formulas in Excel/Sheets, so prefix with an apostrophe.
  final s =
      RegExp(r'[=+\-@]').hasMatch(raw.substring(0, 1)) ? "'$raw" : raw;
  return s.contains(',') || s.contains('"') || s.contains('\n')
      ? '"${s.replaceAll('"', '""')}"'
      : s;
}

/// Pastel stat tile used at the top of both report screens.
class ReportHeadTile extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  const ReportHeadTile(
      {super.key, required this.value, required this.label, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: DSRadii.buttonBr,
          boxShadow: dsEdge(DSColors.edgeSoft, h: 4),
        ),
        child: Column(children: [
          Text(value,
              style: DSText.h2.copyWith(fontSize: 18, color: DSColors.navy)),
          const SizedBox(height: 2),
          Text(label, style: DSText.caption.copyWith(color: DSColors.navy)),
        ]),
      ),
    );
  }
}

/// Two-column pre/post chart — custom painter per spec (columns, baseline,
/// labels). Null values render a dashed empty column with "—".
class PrePostChart extends StatelessWidget {
  final num? pre;
  final num? post;
  const PrePostChart({super.key, required this.pre, required this.post});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pre-test ${pre ?? '—'}%, post-test ${post ?? '—'}%',
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: CustomPaint(painter: _PrePostPainter(pre, post)),
      ),
    );
  }
}

class _PrePostPainter extends CustomPainter {
  final num? pre;
  final num? post;
  _PrePostPainter(this.pre, this.post);

  void _dashRRect(Canvas canvas, RRect rr, Paint paint) {
    final path = Path()..addRRect(rr);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        final end = math.min(d + 6, m.length);
        canvas.drawPath(m.extractPath(d, end), paint);
        d = end + 6;
      }
    }
  }

  void _label(Canvas canvas, String text, TextStyle style, Offset c) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const bw = 56.0, gap = 48.0, maxH = 118.0;
    final base = size.height - 26.0;
    final cols = [
      ('Pre-test', pre, DSColors.blue, size.width / 2 - gap / 2 - bw),
      ('Post-test', post, DSColors.teal, size.width / 2 + gap / 2),
    ];
    canvas.drawLine(
      Offset(cols[0].$4 - 24, base + 0.5),
      Offset(cols[1].$4 + bw + 24, base + 0.5),
      Paint()
        ..color = DSColors.track
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    for (final (lab, v, color, x) in cols) {
      final h = v == null ? 0.0 : math.max(8.0, v / 100 * maxH);
      if (v == null) {
        _dashRRect(
          canvas,
          RRect.fromRectAndRadius(Rect.fromLTWH(x, base - maxH, bw, maxH),
              const Radius.circular(14)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = DSColors.track,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, base - h, bw, h), const Radius.circular(14)),
          Paint()..color = color,
        );
      }
      _label(
        canvas,
        v == null ? '—' : '${v.round()}%',
        DSText.label.copyWith(fontSize: 15, color: DSColors.navy),
        Offset(x + bw / 2, base - h - 14),
      );
      _label(
        canvas,
        lab,
        DSText.caption.copyWith(color: DSColors.muted),
        Offset(x + bw / 2, base + 14),
      );
    }
  }

  @override
  bool shouldRepaint(_PrePostPainter old) => old.pre != pre || old.post != post;
}

/// Labeled ring in the "Overall progress" / "Class averages" card.
class ReportRing extends StatelessWidget {
  final String label;
  final double? value;
  final int series;
  const ReportRing(
      {super.key,
      required this.label,
      required this.value,
      required this.series});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // FittedBox scales the fixed 68px ring down to its Expanded share —
      // 4×68 overflows on narrow screens.
      FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 68,
          height: 68,
          child: DSRingChart(
            size: 68,
            thickness: 12,
            slices: value == null
                ? const []
                : [DSRingSlice(value!, series: series)],
            center: Text(value == null ? '—' : '${value!.round()}%',
                style:
                    DSText.label.copyWith(fontSize: 13, color: DSColors.navy)),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: DSText.caption.copyWith(color: DSColors.muted),
          overflow: TextOverflow.ellipsis),
    ]);
  }
}

/// One assessment score row: title, bar (or dashed empty track), right-aligned
/// value, and the sun "Not released" chip for unreleased scores.
class ReportScoreRow extends StatelessWidget {
  final Json assessment;
  final String emptyLabel;
  final String? caption;
  const ReportScoreRow(
      {super.key,
      required this.assessment,
      this.emptyLabel = 'Not taken',
      this.caption});

  @override
  Widget build(BuildContext context) {
    final score = assessment['score'] ?? assessment['avg'];
    final released = assessment['released'] == true;
    return Row(children: [
      SizedBox(
        width: 104,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${assessment['title'] ?? ''}',
              style: DSText.caption
                  .copyWith(fontWeight: FontWeight.w600, color: DSColors.ink),
              overflow: TextOverflow.ellipsis),
          if (caption != null)
            Text(caption!,
                style: DSText.caption
                    .copyWith(fontSize: 11, color: DSColors.muted),
                overflow: TextOverflow.ellipsis),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: score == null
            ? Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: DSRadii.pillBr,
                  border: Border.all(
                      color: DSColors.track,
                      width: 2,
                      style: BorderStyle.solid),
                ),
              )
            : DSProgressBar(
                value: (score as num) / 100,
                size: DSProgressBarSize.lg,
                tone: toneFor('${assessment['kind']}'),
              ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 64,
        child: Text(
          score == null ? emptyLabel : '${(score as num).round()}%',
          textAlign: TextAlign.right,
          style: score == null
              ? DSText.caption.copyWith(color: DSColors.muted)
              : DSText.label.copyWith(color: DSColors.navy),
        ),
      ),
      if (score != null && !released) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: DSColors.sun,
            borderRadius: DSRadii.pillBr,
          ),
          child: Text('Not released',
              style: DSText.label.copyWith(fontSize: 11, color: DSColors.navy)),
        ),
      ],
    ]);
  }
}

/// One lesson progress row: title, bar, right-aligned percent.
class ReportLessonRow extends StatelessWidget {
  final Json lesson;
  const ReportLessonRow({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final pct = ((lesson['percent'] ?? lesson['avg']) as num?)?.toDouble() ?? 0;
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text('${lesson['title'] ?? ''}',
            style: DSText.caption
                .copyWith(fontWeight: FontWeight.w600, color: DSColors.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: DSProgressBar(
          value: pct / 100,
          size: DSProgressBarSize.lg,
          tone: pct >= 100
              ? DSProgressBarTone.teal
              : pct > 0
                  ? DSProgressBarTone.sun
                  : DSProgressBarTone.blue,
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 42,
        child: Text('${pct.round()}%',
            textAlign: TextAlign.right,
            style: DSText.label.copyWith(color: DSColors.navy)),
      ),
    ]);
  }
}

/// Dashed report-empty slot — illustration + caption.
class ReportEmpty extends StatelessWidget {
  final String message;
  const ReportEmpty(
      {super.key,
      this.message =
          'No attempts yet — scores appear here once the student takes an assessment.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: DSRadii.tileBr,
        border: Border.all(color: DSColors.pastelBlue, width: 2),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/illustrations/report_empty.png',
            width: 120, height: 90),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: DSText.body.copyWith(color: DSColors.muted),
        ),
      ]),
    );
  }
}
