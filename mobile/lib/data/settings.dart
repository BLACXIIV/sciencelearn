import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

enum AppMode { system, dark, light }

class Appearance {
  const Appearance({this.mode = AppMode.system, this.accentId = 'blue', this.surface = SurfaceStyle.flat});
  final AppMode mode;
  final String accentId;
  final SurfaceStyle surface;

  Appearance copy({AppMode? mode, String? accentId, SurfaceStyle? surface}) =>
      Appearance(mode: mode ?? this.mode, accentId: accentId ?? this.accentId, surface: surface ?? this.surface);

  /// The palette currently in effect (system resolves at read time).
  AppPalette get palette {
    final dark = switch (mode) {
      AppMode.dark => true,
      AppMode.light => false,
      AppMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
    };
    return dark ? darkPalette : lightPalette;
  }

  AccentDef get accent => accentById(accentId);
}

class AppearanceNotifier extends StateNotifier<Appearance> {
  AppearanceNotifier() : super(const Appearance()) {
    _load();
  }

  static const _key = 'sl.appearance';

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = Appearance(
        mode: AppMode.values.asNameMap()[p.getString('$_key.mode')] ?? AppMode.system,
        accentId: p.getString('$_key.accent') ?? 'blue',
        surface: SurfaceStyle.values.asNameMap()[p.getString('$_key.surface')] ?? SurfaceStyle.flat,
      );
      _apply();
    } catch (_) {
      // No plugin (widget tests, previews): keep defaults.
    }
  }

  void _apply() =>
      AppColors.apply(palette: state.palette, accent: state.accent, surface: state.surface);

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('$_key.mode', state.mode.name);
      await p.setString('$_key.accent', state.accentId);
      await p.setString('$_key.surface', state.surface.name);
    } catch (_) {}
  }

  void setMode(AppMode m) { state = state.copy(mode: m); _apply(); _save(); }
  void setAccent(String id) { state = state.copy(accentId: id); _apply(); _save(); }
  void setSurface(SurfaceStyle s) { state = state.copy(surface: s); _apply(); _save(); }
}

final appearanceProvider = StateNotifierProvider<AppearanceNotifier, Appearance>(
  (ref) => AppearanceNotifier(),
);
