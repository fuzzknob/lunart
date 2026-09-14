import '../request.dart';
import '../response.dart';
import '../types.dart';

class SecureHeadersOptions({
  final bool xContentTypeOptions = true,
  final bool strictTransportSecurity = true,
  final int strictTransportSecurityMaxAge = 31536000,
  final bool strictTransportSecurityIncludeSubDomains = true,
  final bool strictTransportSecurityPreload = false,
  final bool strictTransportSecurityOnlyWhenSecureRequest = true,
  final String? contentSecurityPolicy = "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'",
  final String? xFrameOptions = 'SAMEORIGIN',
  final String? xXssProtection = '0',
  final String? referrerPolicy = 'strict-origin-when-cross-origin',
  final String? crossOriginOpenerPolicy = 'same-origin',
  final String? crossOriginResourcePolicy = 'same-origin',
  final String? crossOriginEmbedderPolicy,
  final String? originAgentCluster = '?1',
  final String? xDnsPrefetchControl = 'off',
  final String? xPermittedCrossDomainPolicies = 'none',
  final String? xDownloadOptions = 'noopen',
});

Middleware secureHeaders({
  bool xContentTypeOptions = true,
  bool strictTransportSecurity = true,
  int strictTransportSecurityMaxAge = 31536000,
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
  final options = SecureHeadersOptions(
    xContentTypeOptions: xContentTypeOptions,
    strictTransportSecurity: strictTransportSecurity,
    strictTransportSecurityMaxAge: strictTransportSecurityMaxAge,
    strictTransportSecurityIncludeSubDomains:
        strictTransportSecurityIncludeSubDomains,
    strictTransportSecurityPreload: strictTransportSecurityPreload,
    strictTransportSecurityOnlyWhenSecureRequest:
        strictTransportSecurityOnlyWhenSecureRequest,
    contentSecurityPolicy: contentSecurityPolicy,
    xFrameOptions: xFrameOptions,
    xXssProtection: xXssProtection,
    referrerPolicy: referrerPolicy,
    crossOriginOpenerPolicy: crossOriginOpenerPolicy,
    crossOriginResourcePolicy: crossOriginResourcePolicy,
    crossOriginEmbedderPolicy: crossOriginEmbedderPolicy,
    originAgentCluster: originAgentCluster,
    xDnsPrefetchControl: xDnsPrefetchControl,
    xPermittedCrossDomainPolicies: xPermittedCrossDomainPolicies,
    xDownloadOptions: xDownloadOptions,
  );

  return (Request request, Next next) async {
    final response = Res.any(await next());

    return response.addHeaders(
      _buildSecureHeaders(
        request,
        options,
      ),
    );
  };
}

Map<String, String> _buildSecureHeaders(
  Request request,
  SecureHeadersOptions options,
) {
  final headers = <String, String>{};

  if (options.xContentTypeOptions) {
    headers['X-Content-Type-Options'] = 'nosniff';
  }

  if (options.strictTransportSecurity) {
    final isSecureRequest = _isSecureRequest(request);

    if (!options.strictTransportSecurityOnlyWhenSecureRequest ||
        isSecureRequest) {
      var strictTransportSecurityValue =
          'max-age=${options.strictTransportSecurityMaxAge}';

      if (options.strictTransportSecurityIncludeSubDomains) {
        strictTransportSecurityValue =
            '$strictTransportSecurityValue; includeSubDomains';
      }

      if (options.strictTransportSecurityPreload) {
        strictTransportSecurityValue = '$strictTransportSecurityValue; preload';
      }

      headers['Strict-Transport-Security'] = strictTransportSecurityValue;
    }
  }

  if (options.contentSecurityPolicy != null) {
    headers['Content-Security-Policy'] = options.contentSecurityPolicy!;
  }

  if (options.xFrameOptions != null) {
    headers['X-Frame-Options'] = options.xFrameOptions!;
  }

  if (options.xXssProtection != null) {
    headers['X-XSS-Protection'] = options.xXssProtection!;
  }

  if (options.referrerPolicy != null) {
    headers['Referrer-Policy'] = options.referrerPolicy!;
  }

  if (options.crossOriginOpenerPolicy != null) {
    headers['Cross-Origin-Opener-Policy'] = options.crossOriginOpenerPolicy!;
  }

  if (options.crossOriginResourcePolicy != null) {
    headers['Cross-Origin-Resource-Policy'] =
        options.crossOriginResourcePolicy!;
  }

  if (options.crossOriginEmbedderPolicy != null) {
    headers['Cross-Origin-Embedder-Policy'] =
        options.crossOriginEmbedderPolicy!;
  }

  if (options.originAgentCluster != null) {
    headers['Origin-Agent-Cluster'] = options.originAgentCluster!;
  }

  if (options.xDnsPrefetchControl != null) {
    headers['X-DNS-Prefetch-Control'] = options.xDnsPrefetchControl!;
  }

  if (options.xPermittedCrossDomainPolicies != null) {
    headers['X-Permitted-Cross-Domain-Policies'] =
        options.xPermittedCrossDomainPolicies!;
  }

  if (options.xDownloadOptions != null) {
    headers['X-Download-Options'] = options.xDownloadOptions!;
  }

  return headers;
}

bool _isSecureRequest(Request request) {
  final requestCertificate = request.nativeRequest.certificate;

  if (requestCertificate != null) {
    return true;
  }

  final forwardedProtocol = _getHeaderValue(
    request.headers,
    'x-forwarded-proto',
  );

  return forwardedProtocol?.toLowerCase() == 'https';
}

String? _getHeaderValue(Map<String, String> headers, String key) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == key.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}
