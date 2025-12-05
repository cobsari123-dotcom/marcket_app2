import 'package:flutter/material.dart';
import 'package:marcket_app/providers/admin_complaints_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminComplaintsSuggestionsScreen extends StatefulWidget {
  const AdminComplaintsSuggestionsScreen({super.key});

  @override
  State<AdminComplaintsSuggestionsScreen> createState() =>
      _AdminComplaintsSuggestionsScreenState();
}

class _AdminComplaintsSuggestionsScreenState
    extends State<AdminComplaintsSuggestionsScreen> {
  late AdminComplaintsProvider _adminComplaintsProvider;

  @override
  void initState() {
    super.initState();
    _adminComplaintsProvider = Provider.of<AdminComplaintsProvider>(
      context,
      listen: false,
    );
    _adminComplaintsProvider.init(); // Cargar quejas al inicio
  }

  void _showReplyDialog(
    BuildContext context,
    String complaintId,
    AdminComplaintsProvider provider,
  ) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Responder a Queja/Sugerencia'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              hintText: 'Escribe tu respuesta aquí...',
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return; // Add this check
                if (replyController.text.isNotEmpty) {
                  await provider.replyToComplaint(
                    complaintId,
                    replyController.text,
                  );
                  if (!context.mounted) return; // Corrected mounted check
                  Navigator.pop(context);
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
    return Scaffold(
      body: Consumer<AdminComplaintsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }
          if (provider.complaints.isEmpty) {
            return const Center(child: Text('No hay quejas o sugerencias.'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800), // Limit width for list content
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: provider.complaints.length,
                itemBuilder: (context, index) {
                  final complaint = provider.complaints[index];
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'De: ${complaint['userEmail'] ?? 'Anónimo'} (UID: ${complaint['userId'] ?? 'N/A'})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            complaint['message'] ?? 'Sin mensaje.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          if (complaint['reply'] != null)
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.only(top: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text('Respuesta: ${complaint['reply']}'),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Estado: ${complaint['status'] ?? 'pending'} - $formattedDate',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                              TextButton(
                                onPressed: () => _showReplyDialog(
                                  context,
                                  complaint['id'],
                                  provider,
                                ),
                                child: const Text('Responder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
