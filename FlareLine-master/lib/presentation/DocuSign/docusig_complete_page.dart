import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_bloc.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_event.dart';
import 'package:flareline/presentation/bloc/docusign/docusign_state.dart';
import 'dart:html' as html;

class DocuSignCompletePage extends StatefulWidget {
  final String? envelopeId;
  final String? event;

  const DocuSignCompletePage({
    Key? key,
    this.envelopeId,
    this.event,
  }) : super(key: key);

  @override
  State<DocuSignCompletePage> createState() => _DocuSignCompletePageState();
}

class _DocuSignCompletePageState extends State<DocuSignCompletePage> {
  @override
  void initState() {
    super.initState();
    
    // Vérifier le statut de l'enveloppe si l'ID est disponible
    if (widget.envelopeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DocuSignBloc>().add(
          CheckEnvelopeStatusEvent(envelopeId: widget.envelopeId!),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signature terminée'),
        backgroundColor: GlobalColors.primary,
      ),
      body: BlocConsumer<DocuSignBloc, DocuSignState>(
        listener: (context, state) {
          if (state is EnvelopeStatusError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Signature terminée avec succès!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Le document a été signé électroniquement via DocuSign.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (widget.envelopeId != null)
                    Text(
                      'ID de l\'enveloppe: ${widget.envelopeId}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 32),
                  if (state is EnvelopeStatusCheckInProgress)
                    CircularProgressIndicator()
                  else if (state is EnvelopeStatusLoaded)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Statut du document: ${state.envelope.status ?? "Inconnu"}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (state.envelope.completedDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Terminé le: ${state.envelope.completedDate!.toLocal().toString().split('.')[0]}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Naviguer vers la page des détails du terrain
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('Retour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}