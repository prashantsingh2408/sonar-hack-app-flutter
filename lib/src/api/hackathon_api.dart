import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../browse/query_params.dart';
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

  Uri _uri(String path, Map<String, String> query) {
    final base = origin.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<PaginatedResponse<Hackathon>> listHackathons(BuildHackathonListParamsInput input) async {
    final query = buildHackathonListParamsFromState(input);
    return listHackathonsQuery(query);
  }

  /// Shared by main catalog + home rails (query map matches web `URLSearchParams`).
  Future<PaginatedResponse<Hackathon>> listHackathonsQuery(Map<String, String> query) async {
    final uri = _uri('/api/hackathons', query);
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HackathonApiException(
        res.body.isNotEmpty ? res.body : 'Request failed',
        res.statusCode,
      );
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) {
      throw HackathonApiException('Invalid JSON shape');
    }
    final json = Map<String, dynamic>.from(decoded);
    return PaginatedResponse.fromJson(json, Hackathon.fromJson);
  }

  /// GET `/api/hackathons/by-ids?ids=1,2,3` — same as web wishlist/collections.
  Future<List<Hackathon>> getHackathonsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    const maxPerRequest = 100;
    final out = <Hackathon>[];
    for (var i = 0; i < ids.length; i += maxPerRequest) {
      final chunk = ids.sublist(i, math.min(i + maxPerRequest, ids.length));
      final uri = _uri('/api/hackathons/by-ids', {'ids': chunk.join(',')});
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HackathonApiException(res.body.isNotEmpty ? res.body : 'by-ids failed', res.statusCode);
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) throw HackathonApiException('Invalid by-ids JSON');
      final json = Map<String, dynamic>.from(decoded);
      final raw = json['items'];
      if (raw is! List) continue;
      for (final e in raw) {
        final m = coerceJsonObject(e);
        if (m != null) out.add(Hackathon.fromJson(m));
      }
    }
    return out;
  }

  /// GET `/api/hackathons/by-slug?slug=...` — single-hackathon refresh (web detail).
  Future<Hackathon?> getHackathonBySlug(String slug) async {
    final s = slug.trim().toLowerCase();
    if (s.isEmpty) return null;
    final uri = _uri('/api/hackathons/by-slug', {'slug': s});
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 404) return null;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HackathonApiException(res.body, res.statusCode);
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return null;
    final json = Map<String, dynamic>.from(decoded);
    if (json['ok'] != true) return null;
    final m = coerceJsonObject(json['item']);
    if (m == null) return null;
    return Hackathon.fromJson(m);
  }
}

/// Preserves wishlist / collection order after [HackathonApi.getHackathonsByIds].
List<Hackathon> orderHackathonsByIds(List<Hackathon> loaded, List<int> ids) {
  final m = {for (final h in loaded) h.id: h};
  return ids.map((id) => m[id]).whereType<Hackathon>().toList();
}
