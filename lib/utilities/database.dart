import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper class to manage database references for the currently logged-in user.
class Database {
  /// Returns the root Firestore document for the currently logged-in user.
  /// All user-specific data (items, folders, history) should be stored as subcollections under this document.
  static DocumentReference get userDoc {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not logged in. Cannot access database.');
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }
}
