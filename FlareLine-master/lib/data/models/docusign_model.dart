import 'package:flareline/domain/entities/docusign_entity.dart';

class DocuSignModel extends DocuSignEntity {
  DocuSignModel({
    String? envelopeId,
    String? status,
    DateTime? createdDate,
    DateTime? sentDate,
    DateTime? completedDate,
    String? documentUrl,
  }) : super(
    envelopeId: envelopeId,
    status: status,
    createdDate: createdDate,
    sentDate: sentDate,
    completedDate: completedDate,
    documentUrl: documentUrl,
  );
  
  factory DocuSignModel.fromJson(Map<String, dynamic> json) {
    return DocuSignModel(
      envelopeId: json['envelopeId'] as String?,
      status: json['status'] as String?,
      createdDate: json['created'] != null ? DateTime.parse(json['created']) : null,
      sentDate: json['sent'] != null ? DateTime.parse(json['sent']) : null,
      completedDate: json['completed'] != null ? DateTime.parse(json['completed']) : null,
      documentUrl: json['documentUrl'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'envelopeId': envelopeId,
      'status': status,
      'created': createdDate?.toIso8601String(),
      'sent': sentDate?.toIso8601String(),
      'completed': completedDate?.toIso8601String(),
      'documentUrl': documentUrl,
    };
  }
  
  static List<DocuSignModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => DocuSignModel.fromJson(json)).toList();
  }
}