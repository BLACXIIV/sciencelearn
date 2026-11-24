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
  static const IconData shield = LucideIcons.shield;

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
  static const IconData arrow = LucideIcons.arrowRight;
  static const IconData alert = LucideIcons.alertCircle;
  static const IconData openExternal = LucideIcons.externalLink;
  static const IconData play = LucideIcons.play;
  static const IconData add = LucideIcons.plus;
  static const IconData tip = LucideIcons.lightbulb;
  static const IconData pending = LucideIcons.timer;
  static const IconData award = LucideIcons.award;
  static const IconData delete = LucideIcons.trash2;
  static const IconData copy = LucideIcons.copy;
}
