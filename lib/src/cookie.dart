import 'dart:io';

class LunartCookie implements Cookie {
  LunartCookie({
    required String name,
    required String value,
    this.httpOnly = true,
    this.secure = true,
    this.domain,
    this.path,
    this.expires,
    this.maxAge,
    this.sameSite,
    this.signed = false,
  }) {
    this.name = Uri.encodeQueryComponent(name);
    this.value = Uri.encodeQueryComponent(value);
  }

  @override
  late final String name;

  @override
  late String value;

  @override
  String? domain;

  @override
  DateTime? expires;

  @override
  bool httpOnly;

  @override
  int? maxAge;

  @override
  String? path;

  @override
  SameSite? sameSite;

  @override
  bool secure;

  bool signed;

  bool hasSigned = false;
}
