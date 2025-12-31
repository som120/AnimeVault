import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get the current user
  static User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Sign out and clear all cache
  static Future<void> signOut() async {
    try {
      // Clear cached images
      await CachedNetworkImage.evictFromCache('');

      // Sign out from Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  /// Get user display name
  static String? get displayName => _auth.currentUser?.displayName;

  /// Get user email
  static String? get email => _auth.currentUser?.email;

  /// Get user photo URL
  static String? get photoURL => _auth.currentUser?.photoURL;
}
