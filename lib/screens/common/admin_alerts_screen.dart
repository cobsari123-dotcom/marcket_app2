import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/utils/theme.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late Query _alertsQuery;

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _alertsQuery = FirebaseDatabase.instance
          .ref('alerts')
          .orderByChild('userId')
          .equalTo(_currentUserId);
    }
  }

  void _showReplyDialog(
      BuildContext context, String alertId, String originalMessage) {
    final replyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Responder a Alerta'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mensaje del administrador:',
                      style: Theme.of(context).textTheme.bodySmall),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 16.0, top: 4.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(originalMessage),
                  ),
                  TextFormField(
                    controller: replyController,
                    decoration: const InputDecoration(
                      labelText: 'Tu Respuesta',
                      hintText: 'Escribe tu respuesta aquí...',
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La respuesta no puede estar vacía.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final alertRef =
                      FirebaseDatabase.instance.ref('alerts/$alertId');
                  try {
                    await alertRef.update({
                      'reply': replyController.text.trim(),
                      'status': 'replied',
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Respuesta enviada.'),
                          backgroundColor: AppTheme.success),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error al enviar la respuesta: $e'),
                          backgroundColor: AppTheme.error),
                    );
                  }
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver las alertas.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Administrador'),
        automaticallyImplyLeading: false, // Remove default back button
      ),
      body: StreamBuilder(
        stream: _alertsQuery.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes alertas.'),
                ],
              ),
            );
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final alerts = data.entries.map((entry) {
            final value = Map<String, dynamic>.from(entry.value as Map);
            value['id'] = entry.key;
            return value;
          }).toList();

          alerts.sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final timestamp =
                  DateTime.fromMillisecondsSinceEpoch(alert['timestamp']);
              final formattedDate =
                  DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
              final status = alert['status'] ?? 'sent';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert['message'],
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      if (alert['reply'] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.only(top: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tu Respuesta:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(alert['reply']),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                          if (status == 'sent')
                            TextButton(
                              onPressed: () => _showReplyDialog(
                                  context, alert['id'], alert['message']),
                              child: const Text('Responder'),
                            )
                          else
                            const Chip(
                              label: Text('Respondido'),
                              backgroundColor: Colors.grey,
                              labelStyle:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
