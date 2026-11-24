/// ScienceLearn Design System — spacing scale.
/// Names match web/src/design-system/tokens/spacing.css (--ds-s*).
abstract final class DSSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
  static const s8 = 80.0;

  /// Mobile screens use the narrow gutter (web --ds-gutter collapses to 20
  /// below 1024px, which is every mobile viewport).
  static const gutter = 20.0;
  static const contentMax = 640.0;
}
