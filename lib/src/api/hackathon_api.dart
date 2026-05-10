import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hackathon.dart';

class HackathonApiException implements Exception {
  HackathonApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => 'HackathonApiException($statusCode): $message';
}

/// Calls the same Next.js BFF as the web app: `GET /api/hackathons`.
class HackathonApi {
  HackathonApi(this.origin);

  /// No trailing slash, e.g. https://hacklens.vercel.app
  final String origin;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = origin.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<PaginatedResponse<Hackathon>> listHackathons({
    int page = 1,
    int pageSize = 20,
    String search = '',
    String sort = 'most_relevant',
  }) async {
    final uri = _uri('/api/hackathons', {
      'page': '$page',
      'page_size': '$pageSize',
      'sort': sort,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });

    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HackathonApiException(
        res.body.isNotEmpty ? res.body : 'Request failed',
        res.statusCode,
      );
    }
    final json = jsonDecode(res.body);
    if (json is! Map<String, dynamic>) {
      throw HackathonApiException('Invalid JSON shape');
    }
    return PaginatedResponse.fromJson(json, Hackathon.fromJson);
  }
}
