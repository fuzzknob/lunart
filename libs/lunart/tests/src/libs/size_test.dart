import 'package:lunart/src/libs/size.dart';
import 'package:test/test.dart';

void main() {
  group('Size constructors', () {
    test('constructors set bytes correctly', () {
      expect(Size(10).bytes, 10);
      expect(Size.zero().bytes, 0);
      expect(Size.fromBytes(7).bytes, 7);
      expect(Size.fromKilobytes(2).bytes, 2048);
      expect(Size.fromMegabytes(2).bytes, 2 * 1024 * 1024);
      expect(Size.fromGigabytes(1).bytes, 1024 * 1024 * 1024);
      expect(Size.fromTerabytes(1).bytes, 1024 * 1024 * 1024 * 1024);
      expect(
        const Size.fromUnits(
          bytes: 5,
          kilobytes: 1,
          megabytes: 1,
          gigabytes: 1,
          terabytes: 1,
        ).bytes,
        5 + 1024 + 1024 * 1024 + 1024 * 1024 * 1024 + 1024 * 1024 * 1024 * 1024,
      );
    });

    test('throws AssertionError for negative bytes', () {
      expect(() => Size(-1), throwsA(isA<AssertionError>()));
    });
  });

  group('Size conversions', () {
    test('unit conversion getters return expected values', () {
      const size = Size.fromUnits(
        bytes: 512,
        kilobytes: 1,
        megabytes: 1,
      );

      final expectedKilobytes = size.bytes / 1024;
      final expectedMegabytes = size.bytes / (1024 * 1024);
      final expectedGigabytes = size.bytes / (1024 * 1024 * 1024);
      final expectedTerabytes = size.bytes / (1024 * 1024 * 1024 * 1024);

      expect(size.inKilobytes, closeTo(expectedKilobytes, 1e-12));
      expect(size.inMegabytes, closeTo(expectedMegabytes, 1e-12));
      expect(size.inGigabytes, closeTo(expectedGigabytes, 1e-15));
      expect(size.inTerabytes, closeTo(expectedTerabytes, 1e-18));
    });
  });

  group('Size arithmetic', () {
    test('plus operator adds sizes', () {
      final result = Size.fromKilobytes(2) + Size.fromBytes(24);

      expect(result.bytes, 2048 + 24);
    });

    test('minus operator subtracts sizes', () {
      final result = Size.fromKilobytes(3) - Size.fromBytes(48);

      expect(result.bytes, 3072 - 48);
    });

    test('multiply operator scales and rounds bytes', () {
      final result = Size.fromBytes(3) * 1.5;

      expect(result.bytes, 5);
    });
  });

  group('Size comparison and equality', () {
    test('comparison operators behave as expected', () {
      final small = Size.fromBytes(100);
      final large = Size.fromBytes(200);

      expect(small < large, isTrue);
      expect(large > small, isTrue);
      expect(small <= large, isTrue);
      expect(large >= small, isTrue);
      expect(small <= small, isTrue);
      expect(large >= large, isTrue);
    });

    test('compareTo returns negative, zero, and positive values', () {
      final a = Size.fromBytes(100);
      final b = Size.fromBytes(100);
      final c = Size.fromBytes(150);

      expect(a.compareTo(c), lessThan(0));
      expect(a.compareTo(b), 0);
      expect(c.compareTo(a), greaterThan(0));
    });

    test('equality and hashCode are based on bytes', () {
      final a = Size.fromKilobytes(2);
      final b = Size.fromBytes(2048);
      final c = Size.fromBytes(2049);

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('Size.toString', () {
    test('formats bytes for values below 1 KB', () {
      expect(Size.fromBytes(999).toString(), '999 B');
    });

    test('formats KB range with one decimal', () {
      expect(Size.fromBytes(1536).toString(), '1.5 KB');
    });

    test('formats MB range with one decimal', () {
      expect(Size.fromMegabytes(2).toString(), '2.0 MB');
    });

    test('formats GB range with one decimal', () {
      expect(Size.fromGigabytes(3).toString(), '3.0 GB');
    });

    test('formats TB range with one decimal', () {
      expect(Size.fromTerabytes(4).toString(), '4.0 TB');
    });
  });
}
