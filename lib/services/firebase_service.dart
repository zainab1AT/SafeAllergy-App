import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/utils/logger.dart';

class FirebaseService {
  FirebaseService._internal({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;

  static const String patientsCollection = 'patients';
  static const String authorizedEmailsCollection = 'authorized_emails';
  static const String auditLogsCollection = 'audit_logs';

  FirebaseFirestore _firestore;

  @visibleForTesting
  void configureForTesting(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  Future<String> createOrUpdatePatient(Patient patient) async {
    try {
      await Logger.logInfo('Saving patient to Firestore');

      if (patient.id != null && patient.id!.isNotEmpty) {
        await _firestore
            .collection(patientsCollection)
            .doc(patient.id)
            .set(patient.toFirestore(), SetOptions(merge: true));
        return patient.id!;
      }

      final docRef = await _firestore
          .collection(patientsCollection)
          .add(patient.toFirestore());
      return docRef.id;
    } catch (e) {
      await Logger.logError('Failed to save patient to Firestore', error: e);
      rethrow;
    }
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      final doc = await _firestore.collection(patientsCollection).doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return Patient.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      await Logger.logError('Failed to fetch patient from Firestore', error: e);
      rethrow;
    }
  }

  Future<bool> isEmailAuthorized(String email) async {
    try {
      final doc = await _firestore
          .collection(authorizedEmailsCollection)
          .doc(email.toLowerCase())
          .get();
      return doc.exists;
    } catch (e) {
      await Logger.logError(
        'Failed to check authorized email in Firestore',
        error: e,
      );
      // Fail closed – treat as not authorized
      return false;
    }
  }

  Future<void> logAudit({
    required String action,
    required String result,
    String? actorEmail,
    String? patientDocId,
    String? tagUid,
    String? details,
  }) async {
    try {
      final data = <String, dynamic>{
        'action': action,
        'result': result,
        'timestamp': FieldValue.serverTimestamp(),
        if (actorEmail != null && actorEmail.isNotEmpty)
          'actorEmail': actorEmail,
        if (patientDocId != null && patientDocId.isNotEmpty)
          'patientDocId': patientDocId,
        if (tagUid != null && tagUid.isNotEmpty) 'tagUid': tagUid,
        if (details != null && details.isNotEmpty) 'details': details,
      };

      await _firestore.collection(auditLogsCollection).add(data);
    } catch (e) {
      // Do not block main flow on audit failures – best effort only.
      await Logger.logError('Failed to write audit log to Firestore', error: e);
    }
  }
}
