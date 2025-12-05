import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/utils/theme.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => MyComplaintsScreenState();
}

class MyComplaintsScreenState extends State<MyComplaintsScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('complaints_suggestions');
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Quejas y Sugerencias'),
      ),
      body: _userId == null
          ? const Center(child: Text('Inicia sesión para ver tus quejas.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Limit width for complaints list
                child: StreamBuilder<DatabaseEvent>(
                  stream: _databaseRef.orderByChild('userId').equalTo(_userId).onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('No has enviado ninguna queja o sugerencia.'));
                    }

                    final Map<dynamic, dynamic> complaintsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                    final List<Map<dynamic, dynamic>> complaints = [];
                    complaintsMap.forEach((key, value) {
                      final complaint = Map<dynamic, dynamic>.from(value);
                      complaint['id'] = key;
                      complaints.add(complaint);
                    });

                    complaints.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

                    return ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = complaints[index];
                        final timestamp = complaint['timestamp'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(complaint['timestamp'])
                            : null;
                        final formattedDate = timestamp != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp)
                            : 'Fecha desconocida';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Asunto: ${complaint['subject'] ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  complaint['message'] ?? 'Sin mensaje.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    'Estado: ${complaint['status'] ?? 'pending'} - $formattedDate',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ),
                                if (complaint['reply'] != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12.0),
                                    margin: const EdgeInsets.only(top: 12.0),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface.withAlpha(128), // Fixed deprecated
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: AppTheme.primary.withAlpha(76)), // Fixed deprecated
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Respuesta del Administrador:',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          complaint['reply'],
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}