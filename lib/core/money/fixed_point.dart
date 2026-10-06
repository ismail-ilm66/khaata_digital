/// Decimal-string ↔ scaled-integer conversion, with no floating point.
///
/// Shared by money amounts (scale = currency decimals) and FX rates
/// (scale = 6, stored as micros). Accepts ASCII, Urdu (۰–۹) and
/// Arabic-Indic (٠–٩) digits, `,`/`٬` grouping, `.`/`٫` decimal point,
/// a leading sign (`-`, `−`, `+`) and exponent notation (`1.5E3`, as
/// spreadsheets sometimes emit).
abstract final class FixedPoint {
  /// Largest accepted magnitude: 15 integer digits keeps every scaled value
  /// (up to scale 3) far inside 64-bit range.
  static const int _maxIntegerDigits = 15;

  static final RegExp _shape = RegExp(
    r'^(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
  );

  /// Parses [input] into an integer scaled by 10^[scale].
  ///
  /// Returns null for anything that is not a plain decimal number. If the
  /// input has more fraction digits than [scale], it is rejected unless
  /// [round] is true, in which case it rounds half away from zero.
  static int? parse(String input, int scale, {bool round = false}) {
    var s = _normalize(input);
    var negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1);
    } else if (s.startsWith('+')) {
      s = s.substring(1);
    }

    final m = _shape.firstMatch(s);
    if (m == null) return null;
    var whole = m.group(1)!;
    var frac = m.group(2) ?? '';
    if (whole.isEmpty && frac.isEmpty) return null;

    // Shift the decimal point for exponent notation.
    final exp = int.parse(m.group(3) ?? '0');
    if (exp > 0) {
      final take = exp < frac.length ? exp : frac.length;
      whole += frac.substring(0, take) + '0' * (exp - take);
      frac = frac.substring(take);
    } else if (exp < 0) {
      final take = -exp < whole.length ? -exp : whole.length;
      frac = '0' * (-exp - take) + whole.substring(whole.length - take) + frac;
      whole = whole.substring(0, whole.length - take);
    }

    whole = whole.replaceFirst(RegExp(r'^0+'), '');
    if (whole.length > _maxIntegerDigits) return null;

    var roundUp = false;
    if (frac.length > scale) {
      final dropped = frac.substring(scale);
      if (!round && dropped.contains(RegExp('[1-9]'))) return null;
      roundUp = round && dropped.codeUnitAt(0) >= 0x35; // '5'
      frac = frac.substring(0, scale);
    }
    frac = frac.padRight(scale, '0');

    var value = int.parse('${whole.isEmpty ? '0' : whole}$frac');
    if (roundUp) value += 1;
    return negative ? -value : value;
  }

  /// 10^[n] as an integer.
  static int pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  /// Formats a scaled integer as a plain decimal string ("1234.50"), without
  /// grouping. Used for persistence and exports.
  static String format(int scaled, int scale) {
    final negative = scaled < 0;
    final digits = scaled.abs().toString().padLeft(scale + 1, '0');
    final cut = digits.length - scale;
    final body = scale == 0
        ? digits
        : '${digits.substring(0, cut)}.${digits.substring(cut)}';
    return negative ? '-$body' : body;
  }

  static String _normalize(String input) {
    final out = StringBuffer();
    for (final r in input.trim().runes) {
      if (r >= 0x06F0 && r <= 0x06F9) {
        out.writeCharCode(0x30 + r - 0x06F0); // Urdu / Persian digits
      } else if (r >= 0x0660 && r <= 0x0669) {
        out.writeCharCode(0x30 + r - 0x0660); // Arabic-Indic digits
      } else if (r == 0x066B) {
        out.write('.'); // Arabic decimal separator
      } else if (r == 0x2212) {
        out.write('-'); // Unicode minus
      } else if (r == 0x2C || r == 0x066C || r == 0x20 || r == 0xA0) {
        // grouping separators and spaces are ignored
      } else {
        out.writeCharCode(r);
      }
    }
    return out.toString();
  }
}
