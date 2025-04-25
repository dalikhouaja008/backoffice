class DocuSignEntity {
  final String? envelopeId;
  final String? status;
  final DateTime? createdDate;
  final DateTime? sentDate;
  final DateTime? completedDate;
  final String? documentUrl;
  
  DocuSignEntity({
    this.envelopeId,
    this.status,
    this.createdDate,
    this.sentDate,
    this.completedDate,
    this.documentUrl,
  });
}