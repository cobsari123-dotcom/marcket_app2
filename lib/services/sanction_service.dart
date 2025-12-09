import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/sanction.dart';

class SanctionService {
  final DatabaseReference _sanctionsRef =
      FirebaseDatabase.instance.ref('sanctions');

  Future<void> sendSanction(Sanction sanction) async {
    try {
      final newSanctionRef = _sanctionsRef.push();
      final newSanctionId = newSanctionRef.key;
      if (newSanctionId == null) {
        throw Exception('Failed to generate a new sanction ID.');
      }
      final sanctionWithId = sanction.copyWith(id: newSanctionId);
      await newSanctionRef.set(sanctionWithId.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Sanction>> getUserSanctionsStream(String userId) {
    return _sanctionsRef
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final List<Sanction> sanctions = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          sanctions.add(Sanction.fromMap(Map<String, dynamic>.from(value), key));
        });
      }
      return sanctions;
    });
  }

  Future<void> updateSanction(Sanction sanction) async {
    try {
      await _sanctionsRef.child(sanction.id).update(sanction.toMap());
    } catch (e) {
      rethrow;
    }
  }
}