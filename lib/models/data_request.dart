class DataRequest {
  final String id;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> requester;
  final Map<String, dynamic> provider;
  final Map<String, dynamic> dataSchema;

  DataRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.requester,
    required this.provider,
    required this.dataSchema,
  });

  factory DataRequest.fromJson(Map<String, dynamic> json) {
    return DataRequest(
      id: json['id'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      requester: json['requester'],
      provider: json['provider'],
      dataSchema: json['dataSchema'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'requester': requester,
      'provider': provider,
      'dataSchema': dataSchema,
    };
  }
}