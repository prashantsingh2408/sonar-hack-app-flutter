// JSON coercion aligned with web `hackathonListNormalize.normalizeHackathonRow`.

int coerceCatalogId(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) {
    final n = int.tryParse(v.trim());
    if (n != null) return n;
  }
  return 0;
}

int? coerceOptionalInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
  return null;
}

bool? coerceTriBool(dynamic v) {
  if (v == true || v == 'true') return true;
  if (v == false || v == 'false') return false;
  return null;
}

String coerceString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

String? coerceOptionalNonEmptyString(dynamic v) {
  if (v == null) return null;
  final s = v is String ? v : v.toString();
  final t = s.trim();
  return t.isEmpty ? null : t;
}

Map<String, dynamic>? coerceJsonObject(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}

class Hackathon {
  Hackathon({
    required this.id,
    required this.title,
    required this.url,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.description,
    required this.organizers,
    required this.platform,
    this.imgUrl,
    this.themes,
    this.prizeAmount,
    this.registrationsCount,
    this.displayLocation,
    this.featured,
    this.managedByDevpostBadge,
    this.listingActive,
    this.whoCanParticipate,
    this.participantAudienceTags,
    this.inviteOnly,
  });

  final int id;
  final String title;
  final String url;
  final String status;
  final String startDate;
  final String? endDate;
  final String description;
  final String organizers;
  final String platform;
  final String? imgUrl;
  final String? themes;
  final String? prizeAmount;
  final int? registrationsCount;
  final String? displayLocation;
  final bool? featured;
  final bool? managedByDevpostBadge;
  final bool? listingActive;
  /// Devpost-style eligibility HTML/text (optional).
  final String? whoCanParticipate;
  /// Comma-separated canonical audience tags (optional).
  final String? participantAudienceTags;
  final bool? inviteOnly;

  factory Hackathon.fromJson(Map<String, dynamic> j) {
    final id = coerceCatalogId(j['id']);
    var title = coerceString(j['title']);
    var url = coerceString(j['url']);
    var status = coerceString(j['status']);
    if (status.isEmpty) status = 'TBA';
    final startRaw = j['start_date'];
    final startDate =
        startRaw != null && coerceString(startRaw).trim().isNotEmpty ? coerceString(startRaw) : '';
    final endDate = coerceOptionalNonEmptyString(j['end_date']);
    final description = coerceString(j['description']);
    var organizers = coerceString(j['organizers']);
    if (organizers.isEmpty) organizers = 'No organizers listed';
    var platform = coerceString(j['platform']);
    if (platform.isEmpty) platform = 'Unknown';

    final themes = coerceOptionalNonEmptyString(j['themes']);
    final prizeAmount = coerceOptionalNonEmptyString(j['prize_amount']);
    final displayLocation = coerceOptionalNonEmptyString(j['display_location']);
    final whoCanParticipate = coerceOptionalNonEmptyString(j['who_can_participate']);
    final participantAudienceTags = coerceOptionalNonEmptyString(j['participant_audience_tags']);

    final imgRaw = j['img_url'];
    final String? imgUrl = imgRaw == null ? null : coerceOptionalNonEmptyString(imgRaw);

    return Hackathon(
      id: id,
      title: title,
      url: url,
      status: status,
      startDate: startDate,
      endDate: endDate,
      description: description,
      organizers: organizers,
      platform: platform,
      imgUrl: imgUrl,
      themes: themes,
      prizeAmount: prizeAmount,
      registrationsCount: coerceOptionalInt(j['registrations_count']),
      displayLocation: displayLocation,
      featured: coerceTriBool(j['featured']),
      managedByDevpostBadge: coerceTriBool(j['managed_by_devpost_badge']),
      listingActive: coerceTriBool(j['listing_active']),
      whoCanParticipate: whoCanParticipate,
      participantAudienceTags: participantAudienceTags,
      inviteOnly: coerceTriBool(j['invite_only']),
    );
  }
}

class PaginatedResponse<T> {
  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    final raw = j['items'];
    final list = <T>[];
    if (raw is List) {
      for (final e in raw) {
        final m = coerceJsonObject(e);
        if (m != null) list.add(parseItem(m));
      }
    }
    return PaginatedResponse(
      items: list,
      total: coerceOptionalInt(j['total']) ?? list.length,
      page: coerceOptionalInt(j['page']) ?? 1,
      pageSize: coerceOptionalInt(j['page_size']) ?? list.length,
      totalPages: coerceOptionalInt(j['total_pages']) ?? 1,
    );
  }
}
