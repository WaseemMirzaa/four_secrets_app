class EmailSendResponse {
  final String message;
  final String status;
  final String? messageId;
  final String? service;
  final String? timestamp;

  EmailSendResponse({
    required this.message,
    required this.status,
    this.messageId,
    this.service,
    this.timestamp,
  });

  factory EmailSendResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return EmailSendResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      messageId: data?['messageId'] ?? json['messageId'],
      service: data?['service'] ?? json['service'],
      timestamp: data?['timestamp'] ?? json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'status': status,
      'messageId': messageId,
      'service': service,
      'timestamp': timestamp,
    };
  }
}
