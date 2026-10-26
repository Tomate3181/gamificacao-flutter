import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';

/// Traduz os erros do Supabase Auth para [AuthFailure].
AuthFailure mapAuthException(AuthException error) {
  if (error is AuthRetryableFetchException) {
    return const AuthFailure.network();
  }

  switch (error.code) {
    case 'invalid_credentials':
      return const AuthFailure.invalidCredentials();
    case 'email_not_confirmed':
      return const AuthFailure.emailNotConfirmed();
    case 'user_already_exists':
    case 'email_exists':
      return const AuthFailure.emailInUse();
    case 'weak_password':
      return const AuthFailure.weakPassword();
    case 'email_address_invalid':
    case 'validation_failed':
      return const AuthFailure.invalidEmail();
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return const AuthFailure.rateLimited();
  }

  if (error is AuthWeakPasswordException) {
    return const AuthFailure.weakPassword();
  }
  return const AuthFailure.unknown();
}
