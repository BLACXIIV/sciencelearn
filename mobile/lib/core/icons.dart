import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Central icon registry. Every icon in the app maps a semantic name to a
/// lucide glyph here, so icon choices stay consistent and swappable in one file.
abstract final class AppIcons {
  static const IconData home = LucideIcons.home;
  static const IconData lessons = LucideIcons.bookOpen;
  static const IconData progress = LucideIcons.barChart3;
  static const IconData account = LucideIcons.user;
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData students = LucideIcons.users;
  static const IconData userAdmin = LucideIcons.userCog;

  static const IconData assessment = LucideIcons.clipboardCheck;
  static const IconData quiz = LucideIcons.listChecks;
  static const IconData preTest = LucideIcons.clipboardList;
  static const IconData postTest = LucideIcons.trophy;
  static const IconData review = LucideIcons.layers;
  static const IconData formulas = LucideIcons.sigma;
  static const IconData keyTerms = LucideIcons.key;
  static const IconData puzzle = LucideIcons.puzzle;

  static const IconData science = LucideIcons.flaskConical;
  static const IconData atom = LucideIcons.atom;
  static const IconData school = LucideIcons.graduationCap;
  static const IconData university = LucideIcons.school;
  static const IconData presentation = LucideIcons.presentation;

  static const IconData back = LucideIcons.arrowLeft;
  static const IconData login = LucideIcons.logIn;
  static const IconData signOut = LucideIcons.logOut;
  static const IconData camera = LucideIcons.camera;
  static const IconData done = LucideIcons.checkCircle2;
  static const IconData settings = LucideIcons.settings;
  static const IconData gain = LucideIcons.trendingUp;
  static const IconData retry = LucideIcons.refreshCw;
  static const IconData offline = LucideIcons.cloudOff;
  static const IconData history = LucideIcons.clock;
  static const IconData inbox = LucideIcons.inbox;
  static const IconData info = LucideIcons.info;
  static const IconData lock = LucideIcons.lock;
  static const IconData mail = LucideIcons.mail;
  static const IconData mailVerified = LucideIcons.mailCheck;
  static const IconData show = LucideIcons.eye;
  static const IconData hide = LucideIcons.eyeOff;
  static const IconData edit = LucideIcons.pencil;
  static const IconData chevron = LucideIcons.chevronRight;
  static const IconData openExternal = LucideIcons.externalLink;
  static const IconData play = LucideIcons.play;
  static const IconData add = LucideIcons.plus;
  static const IconData tip = LucideIcons.lightbulb;
  static const IconData pending = LucideIcons.timer;
  static const IconData award = LucideIcons.award;
  static const IconData delete = LucideIcons.trash2;
  static const IconData copy = LucideIcons.copy;
}

/// 3D emoji assets (Microsoft Fluent Emoji, MIT) used on large feature tiles.
/// Functional UI (nav, actions, states) stays on AppIcons: emoji can't be tinted.
class AppEmoji {
  AppEmoji._();
  static const String lessons = 'open_book_3d.png';
  static const String assessment = 'clipboard_3d.png';
  static const String review = 'spiral_notepad_3d.png';
  static const String progress = 'chart_increasing_3d.png';
  static const String account = 'bust_in_silhouette_3d.png';
  static const String preTest = 'memo_3d.png';
  static const String postTest = 'trophy_3d.png';
  static const String flashcards = 'card_index_dividers_3d.png';
  static const String formulas = 'abacus_3d.png';
  static const String keyTerms = 'key_3d.png';
  static const String science = 'test_tube_3d.png';
  static const String school = 'graduation_cap_3d.png';
}

/// Renders a bundled 3D emoji asset by its AppEmoji filename.
class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;
  const EmojiIcon(this.emoji, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/emoji/$emoji', width: size, height: size, fit: BoxFit.contain);
}
