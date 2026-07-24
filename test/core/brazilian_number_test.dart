import 'package:flutter_test/flutter_test.dart';
import 'package:grade_opera/core/constants/app_constants.dart';
import 'package:grade_opera/core/formatting/brazilian_number.dart';

void main() {
  group('BrazilianNumber', () {
    test('converte centímetros para metros com precisão inteira', () {
      final micrometers = BrazilianNumber.tryParseCentimetersToMicrometers('4');

      expect(micrometers, 40000);
      expect(micrometers! / AppConstants.micrometersPerMeter, 0.04);
    });

    test('aceita vírgula e ponto nos campos numéricos', () {
      expect(BrazilianNumber.tryParseMetersToMicrometers('115,50'), 115500000);
      expect(BrazilianNumber.tryParseMetersToMicrometers('115.50'), 115500000);
      expect(BrazilianNumber.tryParseCentimetersToMicrometers('4,5'), 45000);
    });

    test('formata metros no padrão brasileiro', () {
      expect(BrazilianNumber.metersFromMicrometers(114710000), '114,71');
    });
  });
}
