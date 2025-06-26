class EmailSendResponse {
  final String message;
  final String status;

  EmailSendResponse({
    required this.message,
    required this.status,
  });

  factory EmailSendResponse.fromJson(Map<String, dynamic> json) {
    return EmailSendResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
