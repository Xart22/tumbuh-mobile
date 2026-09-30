class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Sesi telah berakhir atau tidak sah. Silakan masuk kembali.',
    super.statusCode = 401,
    super.details,
  });
}

class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Akses ditolak. Peran Anda tidak memiliki izin untuk tindakan ini.',
    super.statusCode = 403,
    super.details,
  });
}

class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Data atau resource tidak ditemukan.',
    super.statusCode = 404,
    super.details,
  });
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  const ValidationException({
    required super.message,
    super.statusCode = 400,
    this.errors,
    super.details,
  });
}

class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'Terjadi konflik data pada server.',
    super.statusCode = 409,
    super.details,
  });
}

class ServerException extends ApiException {
  const ServerException({
    super.message = 'Terjadi kesalahan pada server. Coba lagi dalam beberapa saat.',
    super.statusCode = 500,
    super.details,
  });
}

class NetworkOfflineException extends ApiException {
  const NetworkOfflineException({
    super.message = 'Koneksi internet tidak tersedia. Transaksi dialihkan ke antrean offline.',
    super.statusCode,
    super.details,
  });
}
