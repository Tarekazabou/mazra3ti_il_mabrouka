import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch farmer data by farmer ID
  Future<Map<String, dynamic>?> getFarmerData(String farmerId) async {
    try {
      final doc = await _firestore.collection('farmers').doc(farmerId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching farmer data: $e');
      return null;
    }
  }

  /// Fetch current measurements for a farmer
  Future<Map<String, dynamic>?> getMeasurements(String farmerId) async {
    try {
      final doc = await _firestore.collection('measurements').doc(farmerId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching measurements: $e');
      return null;
    }
  }

  /// Stream of real-time measurements updates
  Stream<Map<String, dynamic>?> getMeasurementsStream(String farmerId) {
    return _firestore
        .collection('measurements')
        .doc(farmerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  /// Stream of real-time farmer data updates
  Stream<Map<String, dynamic>?> getFarmerDataStream(String farmerId) {
    return _firestore
        .collection('farmers')
        .doc(farmerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  /// Get vegetation list for a farmer
  Future<List<String>> getVegetation(String farmerId) async {
    try {
      final farmerData = await getFarmerData(farmerId);
      if (farmerData != null && farmerData.containsKey('vegetation')) {
        final vegetation = farmerData['vegetation'];
        if (vegetation is List) {
          return vegetation.map((v) => v.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching vegetation: $e');
      return [];
    }
  }

  /// Get measurement history for a farmer
  Future<List<Map<String, dynamic>>> getMeasurementHistory(
    String farmerId, {
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('measurementHistory')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching measurement history: $e');
      return [];
    }
  }

  /// Update measurements (admin use)
  Future<void> updateMeasurements(
    String farmerId,
    Map<String, dynamic> measurements,
  ) async {
    try {
      await _firestore.collection('measurements').doc(farmerId).set(
        {
          ...measurements,
          'farmerId': farmerId,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error updating measurements: $e');
      rethrow;
    }
  }

  /// Update vegetation (admin use)
  Future<void> updateVegetation(
    String farmerId,
    List<String> vegetation,
  ) async {
    try {
      await _firestore.collection('farmers').doc(farmerId).update({
        'vegetation': vegetation,
        'vegetationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating vegetation: $e');
      rethrow;
    }
  }
}
