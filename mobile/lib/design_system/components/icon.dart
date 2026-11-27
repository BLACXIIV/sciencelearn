import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Registered icon names — the only legal icon vocabulary.
/// Mirrors web/src/design-system/icons/Icon.tsx 1:1.
enum DSIconName {
  home(LucideIcons.home),
  lessons(LucideIcons.bookOpen),
  progress(LucideIcons.barChart3),
  account(LucideIcons.user),
  dashboard(LucideIcons.layoutDashboard),
  students(LucideIcons.users),
  userAdmin(LucideIcons.userCog),
  assessment(LucideIcons.clipboardCheck),
  quiz(LucideIcons.listChecks),
  preTest(LucideIcons.clipboardList),
  postTest(LucideIcons.trophy),
  review(LucideIcons.layers),
  formulas(LucideIcons.sigma),
  keyTerms(LucideIcons.keyRound),
  puzzle(LucideIcons.puzzle),
  science(LucideIcons.flaskConical),
  atom(LucideIcons.atom),
  school(LucideIcons.graduationCap),
  university(LucideIcons.school),
  globe(LucideIcons.globe),
  presentation(LucideIcons.presentation),
  shield(LucideIcons.shield),
  back(LucideIcons.arrowLeft),
  login(LucideIcons.logIn),
  signOut(LucideIcons.logOut),
  camera(LucideIcons.camera),
  done(LucideIcons.checkCircle2),
  settings(LucideIcons.settings),
  gain(LucideIcons.trendingUp),
  retry(LucideIcons.refreshCw),
  offline(LucideIcons.cloudOff),
  history(LucideIcons.clock),
  inbox(LucideIcons.inbox),
  info(LucideIcons.info),
  lock(LucideIcons.lock),
  mail(LucideIcons.mail),
  mailVerified(LucideIcons.mailCheck),
  show(LucideIcons.eye),
  hide(LucideIcons.eyeOff),
  edit(LucideIcons.pencil),
  chevron(LucideIcons.chevronRight),
  alert(LucideIcons.circleAlert),
  openExternal(LucideIcons.externalLink),
  copy(LucideIcons.copy),
  play(LucideIcons.play),
  add(LucideIcons.plus),
  tip(LucideIcons.lightbulb),
  pending(LucideIcons.timer),
  award(LucideIcons.award),
  delete(LucideIcons.trash2),
  search(LucideIcons.search),
  close(LucideIcons.x),
  check(LucideIcons.check),
  more(LucideIcons.ellipsis),
  export(LucideIcons.download),
  up(LucideIcons.arrowUp),
  down(LucideIcons.arrowDown);

  const DSIconName(this.data);
  final IconData data;
}

/// Renders a registered line icon at stroke 2 (lucide default weight).
/// `Icon(DSIconName.search, size: 20, color: DSColors.muted)`.
class DSIcon extends StatelessWidget {
  final DSIconName name;
  final double size;
  final Color? color;
  const DSIcon(this.name, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) =>
      Icon(name.data, size: size, color: color);
}
