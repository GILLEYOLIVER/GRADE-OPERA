import 'package:grade_opera/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

abstract final class BrazilianNumber {
  static final NumberFormat _twoDecimals = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  static String normalize(String value) {
    var text = value.trim().replaceAll(RegExp(r'\s'), '');
    if (text.isEmpty) {
      return text;
    }
    final comma = text.lastIndexOf(',');
    final dot = text.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) {
      if (comma > dot) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (comma >= 0) {
      text = text.replaceAll(',', '.');
    }
    return text;
  }

  static double? tryParse(String value) => double.tryParse(normalize(value));

  static int? tryParseScaled(String value, int scale) {
    final normalized = normalize(value);
    if (!RegExp(r'^\+?\d+(?:\.\d+)?$').hasMatch(normalized)) {
      return null;
    }
    final unsigned = normalized.startsWith('+')
        ? normalized.substring(1)
        : normalized;
    final parts = unsigned.split('.');
    final whole = int.parse(parts.first);
    if (parts.length == 1) {
      return whole * scale;
    }
    final fractionDigits = parts[1];
    final denominator = _pow10(fractionDigits.length);
    final numerator = int.parse(fractionDigits) * scale;
    final roundedFraction = (numerator + denominator ~/ 2) ~/ denominator;
    return whole * scale + roundedFraction;
  }

  static int? tryParseMetersToMicrometers(String value) =>
      tryParseScaled(value, AppConstants.micrometersPerMeter);

  static int? tryParseCentimetersToMicrometers(String value) =>
      tryParseScaled(value, AppConstants.micrometersPerCentimeter);

  static String metersFromMicrometers(int value, {int decimals = 2}) {
    final format = NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: decimals,
    );
    return format.format(value / AppConstants.micrometersPerMeter);
  }

  static String percent(double value) => '${_twoDecimals.format(value)}%';

  static String decimal(double value, {int decimals = 2}) {
    final format = NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: decimals,
    );
    return format.format(value);
  }

  static int _pow10(int exponent) {
    var value = 1;
    for (var index = 0; index < exponent; index++) {
      value *= 10;
    }
    return value;
  }
}
