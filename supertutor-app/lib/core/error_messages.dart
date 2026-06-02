import 'package:dio/dio.dart';

/// Converts raw exceptions to user-friendly Uzbek messages.
/// Single source of truth for error UX across the app.
String friendlyError(Object? error) {
  if (error == null) return 'Noma\'lum xato.';

  if (error is DioException) {
    // Network connectivity / DNS
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return '📡 Internetni tekshiring. Ulanish yo\'q.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return '⏳ Ulanish juda sekin. Qayta urinib ko\'ring.';
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return '⏳ Server javob bermayapti. Bir oz keyin urinib ko\'ring.';
    }
    if (error.type == DioExceptionType.cancel) {
      return 'To\'xtatildi.';
    }
    final status = error.response?.statusCode;
    if (status == 429) {
      return '🦉 Biroz dam oling — juda tez yozyapsiz. 1 daqiqadan keyin urinib ko\'ring.';
    }
    if (status == 401 || status == 403) {
      return '🔒 Tizimga kirishingiz kerak.';
    }
    if (status == 404) {
      return 'Bu funksiya hali tayyor emas.';
    }
    if (status == 413) {
      return '📷 Rasm juda katta. Kichikroq rasm tanlang.';
    }
    if (status == 415) {
      return '📷 Bu rasm formati qo\'llab-quvvatlanmaydi.';
    }
    if (status == 503) {
      return '🤖 AI provayderi band. Bir oz keyin urinib ko\'ring.';
    }
    if (status != null && status >= 500) {
      return '⚠️ Serverda muammo. Tez orada tuzatamiz.';
    }
    // Other 4xx
    final detail = _extractDetail(error.response?.data);
    if (detail != null && detail.isNotEmpty) return detail;
  }

  final s = error.toString();
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return '📡 Internetni tekshiring.';
  }
  if (s.contains('TimeoutException')) {
    return '⏳ Server javob bermayapti.';
  }
  if (s.contains('stopped_by_user')) {
    return 'To\'xtatildi.';
  }
  // Fallback — keep short
  final clipped = s.replaceFirst('Exception: ', '');
  return clipped.length > 120 ? '${clipped.substring(0, 120)}…' : clipped;
}

String? _extractDetail(dynamic body) {
  if (body is Map) {
    final d = body['detail'];
    if (d is String) return d;
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
  }
  return null;
}
