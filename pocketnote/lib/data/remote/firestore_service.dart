// lib/data/remote/firestore_service.dart
//
// Central Firestore path helper.
// We store everything under:
// users/{uid}/accounts/{id}
// users/{uid}/categories/{id}
// users/{uid}/records/{id}
// users/{uid}/budgets/{id}

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore db;

  FirestoreService({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> accountsCol(String uid) =>
      userDoc(uid).collection('accounts');

  CollectionReference<Map<String, dynamic>> categoriesCol(String uid) =>
      userDoc(uid).collection('categories');

  CollectionReference<Map<String, dynamic>> recordsCol(String uid) =>
      userDoc(uid).collection('records');

  CollectionReference<Map<String, dynamic>> budgetsCol(String uid) =>
      userDoc(uid).collection('budgets');
}
