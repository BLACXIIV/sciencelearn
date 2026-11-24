import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/design_system.dart';

/// Public landing screen — rebuilt on the design system only: DSButton,
/// DSCard, DSChip, DSQuizCard/DSQuizOption, DSProgressBar, DSStickerBadge,
/// DSIcon, DSText/DSColors/DSRadii. No screen-level colors, fonts, radii
/// or shadows — layout and copy variants only.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _missions = [
    (DSIconName.lessons, DSCardPastel.blue, 'My Lessons', 'Class lessons', '/classes'),
    (DSIconName.assessment, DSCardPastel.yellow, 'Assessment', 'Pre and post-test', '/assessments'),
    (DSIconName.review, DSCardPastel.purple, 'Review', 'Flashcards, formulas', '/review'),
    (DSIconName.progress, DSCardPastel.mint, 'Progress', 'See your gain', '/progress'),
  ];

  static const _steps = [
    (DSColors.pastelBlue, 'Join your class', 'Enter the 6-character code from your teacher.'),
    (DSColors.pastelYellow, 'Learn and practice', 'Read lessons, review key terms and take quizzes.'),
    (DSColors.pastelMint, 'See your gain', 'Compare your pre-test and post-test scores.'),
  ];

  static const _types = [
    'Multiple-choice', 'Identification', 'True or false', 'Problem-solving',
  ];

  static const _options = [
    ('A', 'Momentum', DSQuizOptionState.selected),
    ('B', 'Velocity', DSQuizOptionState.normal),
    ('C', 'Force', DSQuizOptionState.normal),
    ('D', 'Acceleration', DSQuizOptionState.normal),
  ];

  static const _teacherTiles = [
    ('Class management', 'Join codes and approvals', false),
    ('Assessment builder', 'Five question types', false),
    ('Class dashboard', 'Average score and gain', true),
  ];

  bool get _loggedIn => Supabase.instance.client.auth.currentSession != null;

  void _openMission(BuildContext context, String dest) =>
      context.push(_loggedIn ? dest : '/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.paper,
      body: LayoutBuilder(
        builder: (context, bc) => SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _hero(context, bc.maxHeight),
          _section('Pick your mission',
              'Four stops, one clear path from first lesson to final challenge.', _missionGrid(context)),
          _section('How it works',
              'Built around your class, from the first code to the final score.', _stepCards(),
              topPad: 0),
          _section('Quizzes for every kind of question',
              'Multiple-choice, identification, true or false, and problem-solving quizzes.',
              _quizColumn()),
          _teacherBand(),
          _footer(),
          ]),
        ),
      ),
    );
  }

  // ---- 1 · hero ----
  // The hero fills the first screen and the mint CTA is docked at its bottom.

  Widget _hero(BuildContext context, double viewportH) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DSRadii.panel)),
      child: Container(
        height: viewportH,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DSColors.navyDeep, DSColors.navy],
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Row(children: [
                const _LogoMark(40),
                const SizedBox(width: 10),
                Text('ScienceLearn',
                    style: DSText.h3.copyWith(color: DSColors.surface)),
              ]),
            ),
            DSButton(
              variant: DSButtonVariant.white,
              size: DSButtonSize.sm,
              onPressed: () => context.push('/login'),
              child: const Text('Sign in'),
            ),
          ]),
          const SizedBox(height: 10),
          const DSChip(child: Text('Aligned to the DepEd MATATAG curriculum')),
          const SizedBox(height: 16),
          Text.rich(
            const TextSpan(children: [
              TextSpan(text: 'Learn.\nExplore.\n'),
              TextSpan(text: 'Excel.', style: TextStyle(color: DSColors.mint)),
            ]),
            style: DSText.display.copyWith(color: DSColors.surface),
          ),
          const SizedBox(height: 16),
          Text(
            'Science lessons, quizzes and progress tracking for your class.',
            style: DSText.body.copyWith(
                color: DSColors.surface.withValues(alpha: .9)),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(builder: (_, c) {
                final d = math.min(c.maxWidth * .96, c.maxHeight);
                return SizedBox(
                  width: d, height: d,
                  child: Stack(clipBehavior: Clip.none, children: [
                    const Positioned.fill(
                      child: _ArtCircle('assets/illustrations/learning_cuate.svg'),
                    ),
                    Positioned(
                      top: -d * .01, left: d * .27,
                      child: _stroke(24, -0.10),
                    ),
                    Positioned(
                      top: -d * .005, right: d * .10,
                      child: _stroke(16, 0.30),
                    ),
                    Positioned(
                      top: d * .08, left: -d * .06,
                      child: const DSStickerBadge(
                          rotation: -5, child: Text('Join with a class code')),
                    ),
                    Positioned(
                      top: d * .11, right: -d * .06,
                      child: const DSStickerBadge(
                          rotation: 5, child: Text('Pre → post gain')),
                    ),
                    Positioned(
                      bottom: d * .03, right: -d * .01,
                      child: const DSStickerBadge(
                          rotation: -3, child: Text('Physics · Chem · Earth')),
                    ),
                  ]),
                );
              }),
            ),
          ),
          DSButton(
            variant: DSButtonVariant.mint,
            fullWidth: true,
            onPressed: () => context.push('/signup'),
            child: const Text('Start learning'),
          ),
        ]),
      ),
    );
  }

  /// Tiny decorative strokes floating just above the hero circle's top edge.
  Widget _stroke(double w, double angle) => Transform.rotate(
        angle: angle,
        child: Container(
          width: w, height: 5,
          decoration: BoxDecoration(
            color: DSColors.surface.withValues(alpha: .9),
            borderRadius: DSRadii.pillBr,
          ),
        ),
      );


  // ---- section scaffolding ----

  Widget _section(String title, String sub, Widget body, {double topPad = 28}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: DSText.h1),
        const SizedBox(height: 6),
        Text(sub, style: DSText.body.copyWith(color: DSColors.muted)),
        const SizedBox(height: 24),
        body,
      ]),
    );
  }

  // ---- 2 · pick your mission ----

  Widget _missionGrid(BuildContext context) {
    Widget card(int i) => Expanded(
          child: GestureDetector(
            onTap: () => _openMission(context, _missions[i].$5),
            child: DSCard(
              variant: DSCardVariant.pastel,
              pastel: _missions[i].$2,
              tilt: i.isEven,
              tiltLeft: i.isOdd,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                DSIcon(_missions[i].$1, size: 24, color: DSColors.navy),
                const SizedBox(height: 8),
                Text(_missions[i].$3, style: DSText.h3),
                const SizedBox(height: 4),
                Text(_missions[i].$4,
                    style: DSText.bodySm.copyWith(color: DSColors.inkSoft)),
              ]),
            ),
          ),
        );
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        card(0), const SizedBox(width: 14), card(1),
      ]),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        card(2), const SizedBox(width: 14), card(3),
      ]),
    ]);
  }

  // ---- 3 · how it works ----

  Widget _stepCards() => Column(children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 14),
            child: DSCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: _steps[i].$1, borderRadius: DSRadii.chipBr),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: DSText.h3),
                ),
                Text(_steps[i].$2, style: DSText.h3),
                const SizedBox(height: 6),
                Text(_steps[i].$3,
                    style: DSText.bodySm.copyWith(color: DSColors.inkSoft)),
              ]),
            ),
          ),
      ]);

  // ---- 4 · quizzes ----

  Widget _quizColumn() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            for (final t in _types) DSChip(child: Text(t)),
          ],
        ),
        const SizedBox(height: 18),
        DSCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EXAMPLE · GAIN = POST-TEST − PRE-TEST',
                style: DSText.caption.copyWith(
                    color: DSColors.muted, letterSpacing: .4)),
            const SizedBox(height: 8),
            _gainRow('Pre-test', '70%'),
            const SizedBox(height: 6),
            const DSProgressBar(value: .70),
            const SizedBox(height: 12),
            _gainRow('Post-test', '85%'),
            const SizedBox(height: 6),
            const DSProgressBar(value: .85, tone: DSProgressBarTone.success),
          ]),
        ),
        const SizedBox(height: 18),
        DSQuizCard(
          tag: 'Sample · Multiple choice',
          title: const Text(
              'Which quantity is conserved in an isolated system during a collision?'),
          footer: const Text('Momentum and Energy · Topic Quiz'),
          options: [
            for (final o in _options)
              DSQuizOption(letter: o.$1, state: o.$3, child: Text(o.$2)),
          ],
        ),
      ]);

  Widget _gainRow(String label, String pct) => Row(children: [
        Text(label, style: DSText.label),
        const Spacer(),
        Text(pct, style: DSText.label),
      ]);

  // ---- 5 · teachers ----

  Widget _teacherBand() => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: DSRadii.panelBr,
          gradient: const LinearGradient(
            begin: Alignment(-1.05, -0.63), // ≈120deg
            end: Alignment(1.05, 0.63),
            colors: [DSColors.blue, DSColors.navyDeep],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Teachers, you’re covered',
              style: DSText.h1.copyWith(color: DSColors.surface)),
          const SizedBox(height: 8),
          Text(
            'Manage. Monitor. Support. Create classes with a join code, publish lessons with files, build assessments and choose when scores are released.',
            style: DSText.body.copyWith(
                color: DSColors.surface.withValues(alpha: .9)),
          ),
          const SizedBox(height: 20),
          for (final t in _teacherTiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: t.$3 ? DSColors.mint : DSColors.surface,
                  borderRadius: DSRadii.buttonBr,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.$1, style: DSText.title.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(t.$2, style: DSText.caption.copyWith(color: DSColors.inkSoft)),
                ]),
              ),
            ),
        ]),
      );

  // ---- 6 · footer ----

  Widget _footer() => Container(
        color: DSColors.navy,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const _LogoMark(32),
            const SizedBox(width: 8),
            Text('ScienceLearn',
                style: DSText.h3.copyWith(color: DSColors.surface)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Developed by Regym R. Medina · With the support of The Notre Dame of Isulan, Inc.\n'
            'References: DepEd MATATAG Curriculum, Trusted Scientific Resources · Together for a Brighter Future',
            textAlign: TextAlign.center,
            style: DSText.bodySm.copyWith(color: DSColors.surface, height: 1.55),
          ),
        ]),
      );
}

/// Atom logo mark — bare PNG, same as the web mark.
class _LogoMark extends StatelessWidget {
  const _LogoMark(this.size);
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/brand/logo.png', width: size, height: size);
}

/// Storyset SVG on the paper circle (125% bleed) — the hero art container.
class _ArtCircle extends StatelessWidget {
  const _ArtCircle(this.art);
  final String art;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          const BoxDecoration(color: DSColors.paper, shape: BoxShape.circle),
      child: LayoutBuilder(
        builder: (_, c) => Center(
          child: SvgPicture.asset(art, width: c.maxWidth * 1.25),
        ),
      ),
    );
  }
}
