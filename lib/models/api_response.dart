class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data, {String message = 'Success'}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String error, {String? message}) {
    return ApiResponse(
      success: false,
      message: message ?? 'An error occurred',
      error: error,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJson(json['data']) : null,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson(dynamic Function(T) toJson) {
    return {
      'success': success,
      'message': message,
      'data': data != null ? toJson(data as T) : null,
      'error': error,
    };
  }
}

class FeedbackRequest {
  final String medicationId;
  final String feedbackType; // 'incorrect', 'incomplete', 'outdated'
  final String? additionalInfo;
  final String language;

  FeedbackRequest({
    required this.medicationId,
    required this.feedbackType,
    this.additionalInfo,
    this.language = 'tr',
  });

  Map<String, dynamic> toJson() {
    return {
      'medication_id': medicationId,
      'feedback_type': feedbackType,
      'additional_info': additionalInfo,
      'language': language,
    };
  }
}

class OcrRequest {
  final String imageBase64;
  final String language;

  OcrRequest({
    required this.imageBase64,
    this.language = 'tr',
  });

  Map<String, dynamic> toJson() {
    return {
      'image_base64': imageBase64,
      'language': language,
    };
  }
}
