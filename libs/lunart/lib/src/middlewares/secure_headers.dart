import '../request.dart';
import '../response.dart';
import '../types.dart';

Middleware secureHeaders({
  bool xContentTypeOptions = true,
  bool strictTransportSecurity = true,
  Duration strictTransportSecurityMaxAge = const Duration(seconds: 31536000),
  bool strictTransportSecurityIncludeSubDomains = true,
  bool strictTransportSecurityPreload = false,
  bool strictTransportSecurityOnlyWhenSecureRequest = true,
  String? contentSecurityPolicy = "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'",
  String? xFrameOptions = 'SAMEORIGIN',
  String? xXssProtection = '0',
  String? referrerPolicy = 'strict-origin-when-cross-origin',
  String? crossOriginOpenerPolicy = 'same-origin',
  String? crossOriginResourcePolicy = 'same-origin',
  String? crossOriginEmbedderPolicy,
  String? originAgentCluster = '?1',
  String? xDnsPrefetchControl = 'off',
  String? xPermittedCrossDomainPolicies = 'none',
  String? xDownloadOptions = 'noopen',
}) {
  return (Request request, Next next) async {
    final response = Res.any(await next());
    final headers = <String, String>{};

    if (xContentTypeOptions) {
      headers['X-Content-Type-Options'] = 'nosniff';
    }

    if (strictTransportSecurity) {
      if (!strictTransportSecurityOnlyWhenSecureRequest || request.secure) {
        var strictTransportSecurityValue =
            'max-age=${strictTransportSecurityMaxAge.inSeconds}';

        if (strictTransportSecurityIncludeSubDomains) {
          strictTransportSecurityValue =
              '$strictTransportSecurityValue; includeSubDomains';
        }

        if (strictTransportSecurityPreload) {
          strictTransportSecurityValue =
              '$strictTransportSecurityValue; preload';
        }

        headers['Strict-Transport-Security'] = strictTransportSecurityValue;
      }
    }

    if (contentSecurityPolicy != null) {
      headers['Content-Security-Policy'] = contentSecurityPolicy;
    }

    if (xFrameOptions != null) {
      headers['X-Frame-Options'] = xFrameOptions;
    }

    if (xXssProtection != null) {
      headers['X-XSS-Protection'] = xXssProtection;
    }

    if (referrerPolicy != null) {
      headers['Referrer-Policy'] = referrerPolicy;
    }

    if (crossOriginOpenerPolicy != null) {
      headers['Cross-Origin-Opener-Policy'] = crossOriginOpenerPolicy;
    }

    if (crossOriginResourcePolicy != null) {
      headers['Cross-Origin-Resource-Policy'] = crossOriginResourcePolicy;
    }

    if (crossOriginEmbedderPolicy != null) {
      headers['Cross-Origin-Embedder-Policy'] = crossOriginEmbedderPolicy;
    }

    if (originAgentCluster != null) {
      headers['Origin-Agent-Cluster'] = originAgentCluster;
    }

    if (xDnsPrefetchControl != null) {
      headers['X-DNS-Prefetch-Control'] = xDnsPrefetchControl;
    }

    if (xPermittedCrossDomainPolicies != null) {
      headers['X-Permitted-Cross-Domain-Policies'] =
          xPermittedCrossDomainPolicies;
    }

    if (xDownloadOptions != null) {
      headers['X-Download-Options'] = xDownloadOptions;
    }

    return response.addHeaders(headers);
  };
}
