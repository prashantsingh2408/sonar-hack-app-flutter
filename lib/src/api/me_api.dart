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
    final map = body is Map<String, dynamic> ? body : (body is Map ? Map<String, dynamic>.from(body) : null);
    if (map == null || map['ok'] != true) {
      throw MeApiException('Unexpected wishlist response', res.statusCode);
    }
    final items = map['items'];
    if (items is! List) return [];
    final ids = <int>[];
    for (final e in items) {
      final row = coerceJsonObject(e);
      if (row != null && row['item_type'] == 'hackathon') {
        final parsed = coerceOptionalInt(row['item_id']);
        if (parsed != null) ids.add(parsed);
      }
    }
    return ids;
  }

  /// POST add or DELETE remove — mirrors Next `/api/me/wishlist`.
  Future<void> setWishlistHackathon(int hackathonId, bool add) async {
    if (add) {
      final uri = _uri('/api/me/wishlist');
      final res = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...bearerHeaders(accessToken),
        },
        body: jsonEncode({'item_id': hackathonId, 'item_type': 'hackathon'}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw MeApiException(res.body, res.statusCode);
      }
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MeApiException(res.body, res.statusCode);
    }
    final map = coerceJsonObject(body);
    if (map == null || map['ok'] != true) {
      throw MeApiException(res.body, res.statusCode);
    }
    } else {
      final uri = _uri('/api/me/wishlist', {
        'item_id': '$hackathonId',
        'item_type': 'hackathon',
      });
      final res = await http.delete(
        uri,
        headers: {'Accept': 'application/json', ...bearerHeaders(accessToken)},
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw MeApiException(res.body, res.statusCode);
      }
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MeApiException(res.body, res.statusCode);
    }
    final map = coerceJsonObject(body);
    if (map == null || map['ok'] != true) {
      throw MeApiException(res.body, res.statusCode);
    }
    }
  }

  Future<List<Map<String, dynamic>>> getCollections() async {
    final uri = _uri('/api/me/collections');
    final res = await http.get(uri, headers: {'Accept': 'application/json', ...bearerHeaders(accessToken)});
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw MeApiException(res.body, res.statusCode);
    }
    final root = coerceJsonObject(body);
    if (root == null || root['ok'] != true) {
      return [];
    }
    final raw = root['collections'];
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      final m = coerceJsonObject(e);
      if (m != null) out.add(m);
    }
    return out;
  }

  Future<List<dynamic>> getHackathonNotificationItems() async {
    final uri = _uri('/api/me/hackathon-notification-prefs');
    final res = await http.get(uri, headers: {'Accept': 'application/json', ...bearerHeaders(accessToken)});
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) return [];
    final root = coerceJsonObject(body);
    if (root == null || root['ok'] != true) return [];
    final items = root['items'];
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
      final m = coerceJsonObject(e);
      if (m != null) out.add(Hackathon.fromJson(m));
    }
    return out;
  }
}
