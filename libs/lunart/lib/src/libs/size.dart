class Size implements Comparable<Size> {
  static const int _kb = 1024;

  final int bytes;

  const Size(this.bytes) : assert(bytes >= 0);

  const Size.zero() : bytes = 0;

  const Size.fromUnits({
    int bytes = 0,
    int kilobytes = 0,
    int megabytes = 0,
    int gigabytes = 0,
    int terabytes = 0,
  }) : bytes =
           bytes +
           kilobytes * _kb +
           megabytes * _kb * _kb +
           gigabytes * _kb * _kb * _kb +
           terabytes * _kb * _kb * _kb * _kb;

  const Size.fromBytes(this.bytes);
  const Size.fromKilobytes(int kilobytes) : bytes = kilobytes * _kb;
  const Size.fromMegabytes(int megabytes) : bytes = megabytes * _kb * _kb;
  const Size.fromGigabytes(int gigabytes) : bytes = gigabytes * _kb * _kb * _kb;
  const Size.fromTerabytes(int terabytes)
    : bytes = terabytes * _kb * _kb * _kb * _kb;

  double get inKilobytes => bytes / _kb;
  double get inMegabytes => bytes / (_kb * _kb);
  double get inGigabytes => bytes / (_kb * _kb * _kb);
  double get inTerabytes => bytes / (_kb * _kb * _kb * _kb);

  Size operator +(Size other) => Size(bytes + other.bytes);
  Size operator -(Size other) => Size(bytes - other.bytes);
  Size operator *(num factor) => Size((bytes * factor).round());

  bool operator <(Size other) => bytes < other.bytes;
  bool operator >(Size other) => bytes > other.bytes;
  bool operator <=(Size other) => bytes <= other.bytes;
  bool operator >=(Size other) => bytes >= other.bytes;

  @override
  int compareTo(Size other) => bytes.compareTo(other.bytes);

  @override
  bool operator ==(Object other) => other is Size && other.bytes == bytes;

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() {
    if (bytes < _kb) return '$bytes B';
    if (bytes < _kb * _kb) return '${inKilobytes.toStringAsFixed(1)} KB';
    if (bytes < _kb * _kb * _kb) return '${inMegabytes.toStringAsFixed(1)} MB';
    if (bytes < _kb * _kb * _kb * _kb) {
      return '${inGigabytes.toStringAsFixed(1)} GB';
    }

    return '${inTerabytes.toStringAsFixed(1)} TB';
  }
}
