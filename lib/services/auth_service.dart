import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // বর্তমান ইউজারের ফায়ারস্টোর থেকে ডাটা (যেমন নাম) আনার ফাংশন
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      // Error fetching user data
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final userData = await getCurrentUserData();
      if (userData != null && userData.containsKey('familyId')) {
        String familyId = userData['familyId'];
        final snapshot = await _firestore
            .collection('users')
            .where('familyId', isEqualTo: familyId)
            .get();
        return snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
