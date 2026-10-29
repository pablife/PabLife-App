import 'dart:convert';

class ResponseModel<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'success': success,
      'message': message,
      'data': data,
      'status_code': statusCode,
    };
  }

  factory ResponseModel.fromMap(Map<String, dynamic> map) {
    return ResponseModel<T>(
      success: map['success'] ?? false,
      message: map['message'] ?? '',
      data: map['data'],
      statusCode: map['status_code']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ResponseModel.fromJson(String source) =>
      ResponseModel.fromMap(json.decode(source) as Map<String, dynamic>);

  ResponseModel<T> copyWith({
    bool? success,
    String? message,
    T? data,
    int? statusCode,
  }) {
    return ResponseModel<T>(
      success: success ?? this.success,
      message: message ?? this.message,
      data: data ?? this.data,
      statusCode: statusCode ?? this.statusCode,
    );
  }
}
