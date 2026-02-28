import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final GoogleSignIn? _google;

  User? _user;
  bool _loading = true;
  String? _error;

  AuthProvider({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = GoogleSignIn.instance;

  bool get loading => _loading;
  String? get error => _error;

  User? get user => _user;
  String? get uid => _user?.uid;

  bool get isSignedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;

  bool get isGoogleLinked =>
      (_user?.providerData.any((p) => p.providerId == 'google.com') ?? false);

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ REQUIRED for Android (google_sign_in v7+)
      final google = _google;
      if (google != null) {
        await google.initialize(
          serverClientId:
              '933948660702-ij7gf0qe99d5tsqdcd6d0eqoururseum.apps.googleusercontent.com',
        );
      }

      // ✅ userChanges() updates when providers/linking changes
      _auth.userChanges().listen((u) {
        _user = u;
        notifyListeners();
      });

      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      } else {
        _user = _auth.currentUser;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login with Google (may change UID - normal sign in).
  Future<void> signInWithGoogle() async {
    _error = null;
    notifyListeners();

    try {
      final google = _google;
      if (google == null) {
        throw StateError('GoogleSignIn is not available on this platform');
      }

      // Optional: forces account chooser more often
      await google.signOut();

      final googleUser = await google.authenticate();
      final googleAuth = googleUser.authentication;

      final cred = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      await _auth.signInWithCredential(cred);

      // refresh local user snapshot
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Link anonymous -> Google (upgrade, keeps UID).
  Future<void> linkAnonymousToGoogle() async {
    _error = null;
    notifyListeners();

    final current = _auth.currentUser;
    if (current == null) throw StateError('No current user');
    if (!current.isAnonymous) return;

    try {
      final google = _google;
      if (google == null) throw StateError('GoogleSignIn not available');

      // Optional: forces account chooser more often
      await google.signOut();

      final googleUser = await google.authenticate();
      final googleAuth = googleUser.authentication;

      final cred = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final result = await current.linkWithCredential(cred);

      await result.user?.reload();
      _user = _auth.currentUser;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Unlink Google from current user.
  /// If this user was originally anonymous-upgraded, this typically reverts to anonymous.
  Future<void> unlinkGoogle() async {
    _error = null;
    notifyListeners();

    final current = _auth.currentUser;
    if (current == null) throw StateError('No current user');

    final hasGoogle = current.providerData.any(
      (p) => p.providerId == 'google.com',
    );
    if (!hasGoogle) return;

    try {
      await current.unlink('google.com');

      await _auth.currentUser?.reload();
      _user = _auth.currentUser;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Switch linked Google account:
  /// - Unlink google.com
  /// - Link again with a new Google credential (keeps same UID)
  Future<void> switchLinkedGoogle() async {
    _error = null;
    notifyListeners();

    final current = _auth.currentUser;
    if (current == null) throw StateError('No current user');

    final google = _google;
    if (google == null) throw StateError('GoogleSignIn not available');

    final hasGoogle = current.providerData.any(
      (p) => p.providerId == 'google.com',
    );
    if (!hasGoogle) {
      // if not linked, just link (upgrade)
      if (current.isAnonymous) {
        await linkAnonymousToGoogle();
        return;
      }
      // otherwise sign-in flow is more appropriate
      throw StateError('No Google linked to switch.');
    }

    try {
      // Unlink existing Google provider first
      await current.unlink('google.com');

      // Force account chooser so user can pick a different Google
      await google.signOut();

      final googleUser = await google.authenticate();
      final googleAuth = googleUser.authentication;

      final cred = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final result = await current.linkWithCredential(cred);

      await result.user?.reload();
      _user = _auth.currentUser;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _error = null;
    notifyListeners();

    try {
      final google = _google;
      if (google != null) {
        await google.signOut();
      }

      await _auth.signOut();

      // back to anonymous so app continues offline-first
      await _auth.signInAnonymously();

      await _auth.currentUser?.reload();
      _user = _auth.currentUser;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
