import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:district_car_shared/models/models.dart';
import 'auth_service.dart';

enum AuthFailureReason {
  cancelled,
  noInternet,
  playServicesOutdated,
  accountDisabled,
  generic,
}

abstract class AuthState {
  const AuthState();
}

class AuthStateLoggedOut extends AuthState {
  const AuthStateLoggedOut();
}

class AuthStateSigningIn extends AuthState {
  const AuthStateSigningIn();
}

class AuthStateLoggedIn extends AuthState {
  final DistrictUser user;
  const AuthStateLoggedIn(this.user);
}

class AuthStateError extends AuthState {
  final String message;
  final AuthFailureReason reason;
  const AuthStateError(this.message, {this.reason = AuthFailureReason.generic});
}

abstract class AuthRepository {
  DistrictUser? get currentUser;
  Future<DistrictUser> signInWithGoogle();
  Future<DistrictUser> signInAsPlayStoreReviewer();
  Future<bool> doesCustomerProfileExist(String uid);
  Future<void> signOut();
}

class GoogleAuthRepository implements AuthRepository {
  final AuthService _authService;

  GoogleAuthRepository(this._authService);

  @override
  DistrictUser? get currentUser => _authService.currentUser;

  @override
  Future<DistrictUser> signInWithGoogle() => _authService.signInWithGoogle();

  @override
  Future<DistrictUser> signInAsPlayStoreReviewer() => _authService.signInAsPlayStoreReviewer();

  @override
  Future<bool> doesCustomerProfileExist(String uid) => _authService.doesCustomerProfileExist(uid);

  @override
  Future<void> signOut() => _authService.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.watch(authServiceProvider);
  return GoogleAuthRepository(service);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository)
      : super(_repository.currentUser != null
            ? AuthStateLoggedIn(_repository.currentUser!)
            : const AuthStateLoggedOut());

  Future<DistrictUser?> signInWithGoogle() async {
    state = const AuthStateSigningIn();
    try {
      final user = await _repository.signInWithGoogle();
      state = AuthStateLoggedIn(user);
      return user;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      AuthFailureReason reason = AuthFailureReason.generic;
      String friendlyMessage = 'Google Sign-In failed. Please try again.';

      if (errStr.contains('cancel') || errStr.contains('12501') || errStr.contains('closed')) {
        reason = AuthFailureReason.cancelled;
        friendlyMessage = 'Sign-in cancelled. Tap again whenever you are ready.';
      } else if (errStr.contains('network') || errStr.contains('offline') || errStr.contains('connection')) {
        reason = AuthFailureReason.noInternet;
        friendlyMessage = 'Internet connection required. Please check your signal.';
      } else if (errStr.contains('service') || errStr.contains('play-services') || errStr.contains('outdated')) {
        reason = AuthFailureReason.playServicesOutdated;
        friendlyMessage = 'Google Play Services update needed on this device.';
      } else if (errStr.contains('disabled') || errStr.contains('blocked')) {
        reason = AuthFailureReason.accountDisabled;
        friendlyMessage = 'Google account inaccessible. Please select another account.';
      }

      state = AuthStateError(friendlyMessage, reason: reason);
      return null;
    }
  }

  Future<DistrictUser?> signInAsReviewer() async {
    state = const AuthStateSigningIn();
    try {
      final user = await _repository.signInAsPlayStoreReviewer();
      state = AuthStateLoggedIn(user);
      return user;
    } catch (e) {
      state = AuthStateError('Reviewer sign-in error: $e');
      return null;
    }
  }

  void resetState() {
    if (state is AuthStateError) {
      state = _repository.currentUser != null
          ? AuthStateLoggedIn(_repository.currentUser!)
          : const AuthStateLoggedOut();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthStateLoggedOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
