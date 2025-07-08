// lib/utils/api_exceptions.dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors; // For validation errors

  ApiException(this.statusCode, this.message, {this.errors});

  @override
  String toString() {
    return 'ApiException: Status Code $statusCode, Message: $message, Errors: ${errors.toString()}';
  }
}

class BadRequestException extends ApiException {
  BadRequestException(String message, {Map<String, dynamic>? errors}) : super(400, message, errors: errors);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message, {Map<String, dynamic>? errors}) : super(401, message, errors: errors);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message, {Map<String, dynamic>? errors}) : super(403, message, errors: errors);
}

class NotFoundException extends ApiException {
  NotFoundException(String message, {Map<String, dynamic>? errors}) : super(404, message, errors: errors);
}

class ConflictException extends ApiException {
  ConflictException(String message, {Map<String, dynamic>? errors}) : super(409, message, errors: errors);
}

class ValidationException extends ApiException {
  ValidationException(String message, Map<String, dynamic> errors) : super(422, message, errors: errors);
}

class ServerErrorException extends ApiException {
  ServerErrorException(String message) : super(500, message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() {
    return 'NetworkException: $message';
  }
}