import 'dart:io';

class LunartCookie {
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

  late final String name;

  late String value;

  String? domain;

  DateTime? expires;

  bool httpOnly;

  Duration? maxAge;

  String? path;

  SameSite? sameSite;

  bool secure;

  bool signed;

  bool hasSigned = false;

  factory fromIOCoookie(Cookie cookie) {
    return LunartCookie(
      name: cookie.name,
      value: cookie.value,
      domain: cookie.domain,
      expires: cookie.expires,
      httpOnly: cookie.httpOnly,
      maxAge: cookie.maxAge != null ? Duration(seconds: cookie.maxAge!) : null,
      path: cookie.path,
      sameSite: cookie.sameSite,
      secure: cookie.secure,
    );
  }
}
