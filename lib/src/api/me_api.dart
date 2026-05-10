import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hackathon.dart';

class MeApiException implements Exception {
  MeApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => 'MeApiException($statusCode): $message';
}

Map<String, String> bearerHeaders(String? token) {
  if (token == null || token.isEmpty) return {};
  return {'Authorization': 'Bearer $token'};
}

class MeApi {
  MeApi(this.origin, this.accessToken);

  final String origin;
  final String? accessToken;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = origin.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<List<int>> getWishlistHackathonIds() async {
    final uri = _uri('/api/me/wishlist');
    final res = await http.get(uri, headers: {'Accept': 'application/json', ...bearerHeaders(accessToken)});
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MeApiException(body is Map ? body['hint']?.toString() ?? res.body : res.body, res.statusCode);
    }
    if (body is! Map<String, dynamic> || body['ok'] != true) {
      throw MeApiException('Unexpected wishlist response', res.statusCode);
    }
    final items = body['items'];
    if (items is! List) return [];
    final ids = <int>[];
    for (final e in items) {
      if (e is Map<String, dynamic> && e['item_type'] == 'hackathon') {
        final id = e['item_id'];
        if (id is int) ids.add(id);
      }
    }
    return ids;
  }

  Future<List<Map<String, dynamic>>> getCollections() async {
    final uri = _uri('/api/me/collections');
    final res = await http.get(uri, headers: {'Accept': 'application/json', ...bearerHeaders(accessToken)});
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MeApiException(res.body, res.statusCode);
    }
    if (body is! Map<String, dynamic> || body['ok'] != true) {
      return [];
    }
    final raw = body['collections'];
    if (raw is! List) return [];
    return raw.cast<Map<String, dynamic>>();
  }

  Future<List<dynamic>> getHackathonNotificationItems() async {
    final uri = _uri('/api/me/hackathon-notification-prefs');
    final res = await http.get(uri, headers: {'Accept': 'application/json', ...bearerHeaders(accessToken)});
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) return [];
    if (body is! Map<String, dynamic>) return [];
    if (body['ok'] != true) return [];
    final items = body['items'];
    if (items is List) return items;
    return [];
  }

  /// Personalized rail (`POST /api/me/best-match-hackathons`).
  Future<List<Hackathon>> postBestMatchHackathons() async {
    final uri = _uri('/api/me/best-match-hackathons');
    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...bearerHeaders(accessToken),
      },
      body: '{}',
    );
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return [];
    }
    if (body is! Map<String, dynamic> || body['ok'] != true) {
      return [];
    }
    final raw = body['items'];
    if (raw is! List) return [];
    final out = <Hackathon>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(Hackathon.fromJson(e));
      }
    }
    return out;
  }
}
