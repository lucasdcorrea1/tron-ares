import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Conexão expirou. Tente novamente.');
      case DioExceptionType.connectionError:
        return ApiException('Sem conexão com a internet.');
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.cancel:
        return ApiException('Requisição cancelada.');
      default:
        return ApiException('Erro inesperado. Tente novamente.');
    }
  }

  static ApiException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message;
    if (data is String) {
      message = data;
    } else if (data is Map && data.containsKey('message')) {
      message = data['message'];
    } else {
      switch (statusCode) {
        case 400:
          message = 'Requisição inválida.';
          break;
        case 401:
          message = 'Não autorizado. Faça login novamente.';
          break;
        case 403:
          message = 'Acesso negado.';
          break;
        case 404:
          message = 'Recurso não encontrado.';
          break;
        case 409:
          message = 'Este email já está em uso.';
          break;
        case 500:
          message = 'Erro interno do servidor.';
          break;
        default:
          message = 'Erro desconhecido.';
      }
    }

    return ApiException(message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
