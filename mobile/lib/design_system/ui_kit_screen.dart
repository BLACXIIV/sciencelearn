import 'package:flutter/material.dart';

import 'design_system.dart';

/// Design-system gallery — every token and component, debug builds only.
/// Reachable via `flutter run -t lib/main_dev.dart`.
class UiKitScreen extends StatefulWidget {
  const UiKitScreen({super.key});

  @override
  State<UiKitScreen> createState() => _UiKitScreenState();
}

class _UiKitScreenState extends State<UiKitScreen> {
  String _seg = 'login';
  String _role = 'student';
  String _code = '';
  bool _check = true, _sw = true;
  String _island = 'home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.paper,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DSPageHeader(
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ScienceLearn UI Kit',
                    style: DSText.h1.copyWith(color: DSColors.surface)),
                const SizedBox(height: 4),
                Text('Design-system gallery — debug builds only.',
                    style: DSText.bodySm.copyWith(color: DSColors.pastelBlue)),
              ],
            ),
          ),
          const SizedBox(height: DSSpacing.s5),
          _tokens(),
          _buttons(),
          _fields(),
          _choices(),
          _surfaces(),
          _display(),
          _quiz(),
          _nav(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ——— sections ———

  Widget _sec(String title, List<Widget> children) => DSPageSection(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _rowLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(t.toUpperCase(),
            style: DSText.caption.copyWith(
                color: DSColors.muted,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w500)),
      );

  Widget _tokens() => _sec('Tokens', [
        _rowLabel('Colors'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final (n, c) in [
            ('navy', DSColors.navy),
            ('navyDeep', DSColors.navyDeep),
            ('blue', DSColors.blue),
            ('blueDark', DSColors.blueDark),
            ('mint', DSColors.mint),
            ('sun', DSColors.sun),
            ('paper', DSColors.paper),
            ('pastelBlue', DSColors.pastelBlue),
            ('pastelYellow', DSColors.pastelYellow),
            ('pastelPurple', DSColors.pastelPurple),
            ('pastelMint', DSColors.pastelMint),
            ('inkSoft', DSColors.inkSoft),
            ('muted', DSColors.muted),
            ('line', DSColors.line),
            ('edgeCard', DSColors.edgeCard),
            ('edgeWhite', DSColors.edgeWhite),
            ('edgeBlue', DSColors.edgeBlue),
            ('edgeMint', DSColors.edgeMint),
            ('edgeNavy', DSColors.edgeNavy),
            ('success', DSColors.success),
            ('warning', DSColors.warning),
            ('error', DSColors.error),
            ('errorSurface', DSColors.errorSurface),
            ('track', DSColors.track),
            ('chart1', DSColors.chart1),
            ('chart2', DSColors.chart2),
            ('chart3', DSColors.chart3),
            ('chart4', DSColors.chart4),
          ])
            _Swatch(n, c),
        ]),
        _rowLabel('Type scale'),
        Text('Display 56', style: DSText.display.copyWith(fontSize: 40)),
        Text('Heading 1 — 30', style: DSText.h1),
        Text('Heading 2 — 24', style: DSText.h2),
        Text('Heading 3 — 21', style: DSText.h3),
        Text('Title — Lexend 600/16', style: DSText.title),
        Text('Body — Inter 16: the quick brown fox.', style: DSText.body),
        Text('Body small — Inter 14', style: DSText.bodySm),
        Text('Label — Lexend 600/13', style: DSText.label),
        Text('Button — Lexend 700/15', style: DSText.button),
        Text('Caption — Inter 12', style: DSText.caption),
        _rowLabel('Radii'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final (n, r) in [
            ('button', DSRadii.button),
            ('input', DSRadii.input),
            ('card', DSRadii.card),
            ('panel', DSRadii.panel),
            ('chip', DSRadii.chip),
            ('pill', 24.0),
          ])
            Column(children: [
              Container(
                width: 72,
                height: 48,
                decoration: BoxDecoration(
                  color: DSColors.pastelBlue,
                  border: Border.all(color: DSColors.line),
                  borderRadius: BorderRadius.circular(r),
                ),
              ),
              Text(n,
                  style: DSText.caption
                      .copyWith(color: DSColors.muted, fontSize: 11)),
            ]),
        ]),
        _rowLabel('Edges (heights 3–6 only)'),
        Wrap(spacing: 16, runSpacing: 12, children: [
          for (final (h, e) in [
            (3, DSColors.edgeCard),
            (4, DSColors.edgeCard),
            (5, DSColors.edgeBlue),
            (6, DSColors.edgeNavy)
          ])
            Column(children: [
              Container(
                width: 72,
                height: 48,
                decoration: BoxDecoration(
                  color: DSColors.surface,
                  border: Border.all(color: DSColors.line),
                  borderRadius: DSRadii.inputBr,
                  boxShadow: dsEdge(e, h: h),
                ),
              ),
              Text('edge $h',
                  style: DSText.caption
                      .copyWith(color: DSColors.muted, fontSize: 11)),
            ]),
        ]),
        _rowLabel('Icon registry'),
        Wrap(spacing: 16, runSpacing: 12, children: [
          for (final n in DSIconName.values)
            Column(children: [
              DSIcon(n, size: 20, color: DSColors.inkSoft),
              Text(n.name,
                  style: DSText.caption
                      .copyWith(color: DSColors.muted, fontSize: 9)),
            ]),
        ]),
      ]);

  Widget _buttons() => _sec('Actions', [
        _rowLabel('Button — variants'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          DSButton(onPressed: () {}, child: const Text('Primary')),
          DSButton(
              variant: DSButtonVariant.mint,
              onPressed: () {},
              child: const Text('Mint')),
          DSButton(
              variant: DSButtonVariant.white,
              onPressed: () {},
              child: const Text('White')),
          DSButton(
              variant: DSButtonVariant.outline,
              onPressed: () {},
              child: const Text('Outline')),
          DSButton(
              variant: DSButtonVariant.danger,
              onPressed: () {},
              child: const Text('Danger')),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: DSColors.navy, borderRadius: DSRadii.buttonBr),
            child: DSButton(
                variant: DSButtonVariant.ghost,
                onPressed: () {},
                child: const Text('Ghost')),
          ),
        ]),
        _rowLabel('Sizes / loading / disabled / icon'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          DSButton(
              size: DSButtonSize.sm,
              onPressed: () {},
              child: const Text('Small')),
          DSButton(
              loading: true, onPressed: () {}, child: const Text('Loading')),
          DSButton(
              disabled: true, onPressed: () {}, child: const Text('Disabled')),
          DSButton(
              leadingIcon: DSIconName.add,
              onPressed: () {},
              child: const Text('With icon')),
        ]),
        const SizedBox(height: 12),
        DSButton(
            fullWidth: true, onPressed: () {}, child: const Text('Full width')),
        _rowLabel('IconButton'),
        Wrap(spacing: 12, children: [
          DSIconButton(
              icon: DSIconName.close, label: 'Close', onPressed: () {}),
          DSIconButton(icon: DSIconName.edit, label: 'Edit', onPressed: () {}),
          DSIconButton(
              icon: DSIconName.delete, label: 'Delete', onPressed: () {}),
          DSIconButton(
              icon: DSIconName.settings,
              label: 'Settings',
              disabled: true,
              onPressed: () {}),
        ]),
      ]);

  Widget _fields() => _sec('Forms', [
        const DSTextField(label: 'Display name', hint: 'Ada Lovelace'),
        const SizedBox(height: 16),
        const DSTextField(
            label: 'With error',
            hint: 'bad@',
            error: 'Enter a valid email address.'),
        const SizedBox(height: 16),
        const DSTextField(
            label: 'With helper',
            hint: 'you@school.edu',
            helper: 'We never share your email.'),
        const SizedBox(height: 16),
        const DSPasswordField(label: 'Password', hint: '••••••••'),
        const SizedBox(height: 16),
        const DSTextArea(label: 'About', hint: 'Tell the class…'),
        const SizedBox(height: 16),
        DSSelect(
          label: 'Grade',
          value: '7',
          onChanged: (_) {},
          options: const [
            DSSelectOption('7', 'Grade 7'),
            DSSelectOption('8', 'Grade 8'),
            DSSelectOption('9', 'Grade 9'),
          ],
        ),
        const SizedBox(height: 16),
        const DSSearchField(label: 'Search', hint: 'Students, classes…'),
        const SizedBox(height: 16),
        DSCodeInput(
          label: 'Class code',
          value: _code,
          onChanged: (v) => setState(() => _code = v),
          error: _code.isNotEmpty && _code.length < 6
              ? 'Enter all 6 characters.'
              : null,
        ),
      ]);

  Widget _choices() => _sec('Choice controls', [
        DSCheckbox(
            label: 'Remember me',
            value: _check,
            onChanged: (v) => setState(() => _check = v)),
        DSSwitch(
            label: 'Daily reminders',
            value: _sw,
            onChanged: (v) => setState(() => _sw = v)),
        const SizedBox(height: 16),
        DSSegmentedControl(
          options: const [
            DSSegment('login', 'Log in'),
            DSSegment('signup', 'Sign up')
          ],
          value: _seg,
          onChanged: (v) => setState(() => _seg = v),
        ),
        const SizedBox(height: 16),
        DSRadioGroup(
          label: 'I am a…',
          value: _role,
          onChanged: (v) => setState(() => _role = v),
          options: const [
            DSRadioOption('student',
                _TileIcon(icon: DSIconName.school, label: 'Student')),
            DSRadioOption('teacher',
                _TileIcon(icon: DSIconName.presentation, label: 'Teacher')),
          ],
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: DSOptionTile(
                icon: DSIconName.school,
                label: 'Student',
                selected: _role == 'student',
                onTap: () => setState(() => _role = 'student')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DSOptionTile(
                icon: DSIconName.presentation,
                label: 'Teacher',
                selected: _role == 'teacher',
                onTap: () => setState(() => _role = 'teacher')),
          ),
        ]),
      ]);

  Widget _surfaces() => _sec('Surfaces', [
        _rowLabel('Card variants'),
        const DSCard(child: Text('White')),
        const SizedBox(height: 12),
        const DSCard(
            variant: DSCardVariant.pastel,
            pastel: DSCardPastel.blue,
            tilt: true,
            child: Text('Pastel + tilt')),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(
              child: DSCard(
                  variant: DSCardVariant.pastel,
                  pastel: DSCardPastel.yellow,
                  child: Text('Yellow'))),
          SizedBox(width: 12),
          Expanded(
              child: DSCard(
                  variant: DSCardVariant.pastel,
                  pastel: DSCardPastel.purple,
                  child: Text('Purple'))),
          SizedBox(width: 12),
          Expanded(
              child: DSCard(
                  variant: DSCardVariant.pastel,
                  pastel: DSCardPastel.mint,
                  child: Text('Mint'))),
        ]),
        const SizedBox(height: 12),
        const DSCard(
            variant: DSCardVariant.trivia,
            child: Text('Trivia — Did you know?')),
        const SizedBox(height: 12),
        const DSCard(variant: DSCardVariant.flat, child: Text('Flat')),
        const SizedBox(height: 12),
        const DSCard(variant: DSCardVariant.navy, child: Text('Navy card')),
        const SizedBox(height: 12),
        const DSPanel(child: Text('Panel — navy, radius 32')),
        _rowLabel('Sheet / Modal / Toast'),
        Wrap(spacing: 12, children: [
          DSButton(
            variant: DSButtonVariant.outline,
            onPressed: () => showDSBottomSheet<void>(context,
                child: Text('Bottom sheet — radius 32, handle, dim barrier.',
                    style: DSText.bodySm)),
            child: const Text('Open sheet'),
          ),
          DSButton(
            variant: DSButtonVariant.outline,
            onPressed: () => showDSModal<void>(
              context,
              title: 'Delete class?',
              body: Text('This removes the class and its roster.',
                  style: DSText.bodySm),
              actions: [
                DSButton(
                    variant: DSButtonVariant.danger,
                    size: DSButtonSize.sm,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Delete')),
              ],
            ),
            child: const Text('Open modal'),
          ),
          DSButton(
            variant: DSButtonVariant.outline,
            onPressed: () => DSToast.show(context,
                message: 'Class code copied.', tone: DSToastTone.success),
            child: const Text('Show toast'),
          ),
        ]),
      ]);

  Widget _display() => _sec('Display', [
        _rowLabel('Chips / StickerBadge / Badges'),
        const Wrap(spacing: 12, runSpacing: 12, children: [
          DSChip(child: Text('White')),
          DSChip(
              variant: DSChipVariant.pastel,
              pastel: DSChipPastel.yellow,
              child: Text('Pastel')),
          DSChip(variant: DSChipVariant.navy, child: Text('Navy')),
          DSChip(variant: DSChipVariant.mint, child: Text('Mint')),
          DSStickerBadge(rotation: -5, child: Text('New unit')),
          DSStickerBadge(rotation: 5, child: Text('Top score')),
          DSStickerBadge(
              rotation: -5, pastel: DSCardPastel.blue, child: Text('Join')),
          DSStickerBadge(
              rotation: 5, pastel: DSCardPastel.mint, child: Text('+15%')),
          DSStickerBadge(
              rotation: -3,
              pastel: DSCardPastel.yellow,
              child: Text('Physics')),
          DSBadge(child: Text('3')),
          DSBadge(tone: DSBadgeTone.mint, child: Text('12')),
          DSBadge(tone: DSBadgeTone.error, child: Text('9+')),
        ]),
        _rowLabel('Progress bars (lg 14 / sm 10)'),
        const DSProgressBar(value: 0.68),
        const SizedBox(height: 10),
        const DSProgressBar(value: 0.68, size: DSProgressBarSize.sm),
        const SizedBox(height: 10),
        const DSProgressBar(value: 0.9, tone: DSProgressBarTone.success),
        _rowLabel('RingChart (chart1..4)'),
        const DSRingChart(
          slices: [
            DSRingSlice(40, series: 1),
            DSRingSlice(25, series: 2),
            DSRingSlice(20, series: 3),
            DSRingSlice(15, series: 4),
          ],
          size: 120,
        ),
        const SizedBox(height: 12),
        const DSRingChart(
          slices: [DSRingSlice(70, series: 1), DSRingSlice(30, series: 0)],
        ),
        _rowLabel('ListItemCard / Thumbnail'),
        const DSListItemCard(
          leading: DSThumbnail(),
          title: Text('Forces in motion'),
          subtitle: Text('Objectives: describe balanced forces'),
          trailing: DSIcon(DSIconName.chevron, color: DSColors.muted),
        ),
        const SizedBox(height: 10),
        const DSListItemCard(
          leading: DSIcon(DSIconName.quiz, size: 22, color: DSColors.blue),
          title: Text('Pre-test: Kinematics'),
          subtitle: Text('10 questions'),
          trailing: DSBadge(tone: DSBadgeTone.mint, child: Text('92%')),
        ),
        const SizedBox(height: 10),
        const DSListItemCard(
          pending: true,
          leading: DSIcon(DSIconName.school, size: 22, color: DSColors.muted),
          title: Text('Physics — Grade 10'),
          subtitle: Text('Waiting for teacher approval'),
          trailing: DSBadge(tone: DSBadgeTone.sun, child: Text('Pending')),
        ),
        _rowLabel('StatCards / Avatars'),
        const Row(children: [
          Expanded(
              child: DSStatCard(
                  icon: DSIconName.progress,
                  value: '82%',
                  label: 'Avg. score')),
          SizedBox(width: 12),
          Expanded(
              child: DSStatCard(
                  icon: DSIconName.students,
                  value: '128',
                  label: 'Students',
                  pastel: DSStatPastel.mint)),
        ]),
        const SizedBox(height: 16),
        const Wrap(spacing: 12, children: [
          DSAvatar(name: 'Ada Lovelace'),
          DSAvatar(name: 'Marie Curie', pastel: DSAvatarPastel.purple),
          DSAvatar(name: 'Alan Turing', pastel: DSAvatarPastel.mint, size: 56),
        ]),
        _rowLabel('EmptyState / Skeleton / Divider'),
        const DSCard(
          variant: DSCardVariant.flat,
          child: DSEmptyState(
            icon: DSIconName.inbox,
            title: 'No classes yet',
            body: 'Join a class with a code from your teacher.',
          ),
        ),
        const SizedBox(height: 16),
        const DSSkeleton(),
        const SizedBox(height: 8),
        const DSSkeleton(width: 200),
        const SizedBox(height: 8),
        const DSSkeleton(shape: DSSkeletonShape.card),
        const DSDivider(label: 'or'),
      ]);

  Widget _quiz() => _sec('Quiz', [
        const DSQuizCard(
          tag: 'Pre-test',
          title: Text('Which planet has the most moons?'),
          options: [
            DSQuizOption(letter: 'A', child: Text('Earth')),
            DSQuizOption(
                letter: 'B',
                state: DSQuizOptionState.selected,
                child: Text('Saturn')),
            DSQuizOption(
                letter: 'C',
                state: DSQuizOptionState.correct,
                child: Text('Saturn — correct!')),
            DSQuizOption(
                letter: 'D',
                state: DSQuizOptionState.wrong,
                child: Text('Jupiter')),
            DSQuizOption(
                letter: 'E',
                state: DSQuizOptionState.disabled,
                child: Text('Mars')),
          ],
          footer: Text('Question 2 of 10'),
        ),
        _rowLabel('QuizNav'),
        DSQuizNav(
          count: 10,
          current: 3,
          answered: const [
            true,
            true,
            false,
            false,
            true,
            false,
            false,
            false,
            true,
            false
          ],
          onSelect: (_) {},
        ),
        _rowLabel('Flashcard'),
        const DSFlashcard(
          front: Text('What is the chemical symbol for water?'),
          back: Text('H₂O'),
        ),
      ]);

  Widget _nav() => _sec('Navigation', [
        _rowLabel('NavBar (top)'),
        DSNavBar(
          brand: const Text('ScienceLearn'),
          items: const [
            DSNavItem('home', 'Home', DSIconName.home),
            DSNavItem('lessons', 'Lessons', DSIconName.lessons),
            DSNavItem('progress', 'Progress', DSIconName.progress),
          ],
          active: _island,
          onSelect: (k) => setState(() => _island = k),
        ),
        _rowLabel('IslandNavBar (docks to screen bottom)'),
        DSIslandNavBar(
          items: const [
            DSNavItem('home', 'Home', DSIconName.home),
            DSNavItem('classes', 'Classes', DSIconName.lessons),
            DSNavItem('progress', 'Progress', DSIconName.progress),
            DSNavItem('account', 'Account', DSIconName.account),
          ],
          active: _island,
          onSelect: (k) => setState(() => _island = k),
        ),
      ]);
}

class _TileIcon extends StatelessWidget {
  final DSIconName icon;
  final String label;
  const _TileIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DSIcon(icon, size: 20, color: DSColors.navy),
          const SizedBox(width: 10),
          Text(label),
        ],
      );
}

class _Swatch extends StatelessWidget {
  final String name;
  final Color color;
  const _Swatch(this.name, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: DSRadii.inputBr,
            border: Border.all(color: DSColors.line),
          ),
        ),
        Text(name,
            style:
                DSText.caption.copyWith(color: DSColors.muted, fontSize: 11)),
      ]);
}
