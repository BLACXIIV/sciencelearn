import 'package:flutter/services.dart';

/// Text pasted from Word/docx often carries Symbol-font glyphs smuggled as
/// private-use characters (U+F0AE = "→") that render as tofu boxes. Maps the
/// common ones back to real Unicode and drops the rest of the private-use
/// range. Idempotent.
const _symbolPua = {
  0xF0AC: '←', 0xF0AD: '↑', 0xF0AE: '→', 0xF0AF: '↓',
  0xF0E0: '→', 0xF0DB: '⇔', 0xF0B7: '•', 0xF0B1: '±',
  0xF0B4: '×', 0xF0B8: '÷', 0xF0A3: '≤', 0xF0B3: '≥',
};

/// Character-level cleaning safe on every keystroke — fixes glyphs without
/// trimming or collapsing spaces (which would fight the user mid-edit).
/// Subscript digits are real Unicode and are kept; grading folds them at
/// compare time (answer_norm in migration 0019).
String cleanChars(String s) {
  final buf = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xE000 && r <= 0xF8FF) {
      buf.write(_symbolPua[r] ?? '');
    } else if (!(r >= 0x200B && r <= 0x200D || r == 0xFEFF)) {
      buf.write(String.fromCharCode(r));
    }
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'[⇒⟶⟹⇨➔➞➟➡]'), '→')
      .replaceAllMapped(RegExp(r'\s*[-=]{1,2}>\s*'), (_) => ' → ')
      .replaceAllMapped(RegExp(r'\s*<[-=]{1,2}\s*'), (_) => ' ← ')
      .replaceAll(' ', ' ')  // NBSP
      .toString();
}

const _subscripts = '₀₁₂₃₄₅₆₇₈₉';

/// Digits right after an element token or ')' are formula subscripts in this
/// domain: '2H2 + O2 -> 2H2O' stores as '2H₂ + O₂ → 2H₂O'. Element symbols
/// always start with a capital (H, Fe, Cl, OH groups) so the match requires
/// '[A-Z][a-z]?' — lowercase words like 'test2' or 'item3' stay untouched,
/// as do spaced digits ('Activity 2').
String _chemSub(String s) => s.replaceAllMapped(
    RegExp(r'([A-Z][a-z]?|\)|\])(\d+)'),
    (m) =>
        m[1]! + m[2]!.split('').map((c) => _subscripts[int.parse(c)]).join());

/// Full normalization for stored text — cleanChars + whitespace tidy +
/// formula subscripts.
String cleanText(String s) => _chemSub(
    cleanChars(s).replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim());

/// cleanText applied to every string inside a JSON-ish structure (answer keys,
/// choice lists). Map keys are ids — left untouched.
dynamic cleanDeep(dynamic v) {
  if (v is String) return cleanText(v);
  if (v is List) return v.map(cleanDeep).toList();
  if (v is Map) return v.map((k, x) => MapEntry(k, cleanDeep(x)));
  return v;
}

/// Formatter for DS text fields with `clean: true` — runs cleanChars live so
/// pasted docx junk never reaches the field. Cursor clamps to the new length.
class CleanTextFormatter extends TextInputFormatter {
  const CleanTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final t = cleanChars(newValue.text);
    if (t == newValue.text) return newValue;
    return TextEditingValue(
      text: t,
      selection: TextSelection(
        baseOffset: newValue.selection.baseOffset.clamp(0, t.length),
        extentOffset: newValue.selection.extentOffset.clamp(0, t.length),
      ),
    );
  }
}
