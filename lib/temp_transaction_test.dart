import 'package:firebase_database/firebase_database.dart';

Future<void> testFirebaseTransaction() async {
  final DatabaseReference testRef = FirebaseDatabase.instance.ref('test_path');

  try {
    final TransactionResult transactionResult = await testRef.runTransaction(
      (Object? currentData) {
        // Convertir y asegurar el tipo
        int currentValue = 0;
        if (currentData is int) {
          currentValue = currentData;
        }

        // Lógica: incrementar
        currentValue = currentValue + 1;

        // Retornar éxito
        return Transaction.success(currentValue);
      },
    );

    if (transactionResult.committed) {
      print('Transaction successful: ${transactionResult.snapshot.value}');
    } else {
      print('Transaction failed or aborted.');
    }
  } catch (e) {
    print('Transaction error: $e');
  }
}