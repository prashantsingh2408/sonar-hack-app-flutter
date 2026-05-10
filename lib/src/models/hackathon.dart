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

  factory Hackathon.fromJson(Map<String, dynamic> j) {
    return Hackathon(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      url: j['url'] as String? ?? '',
      status: j['status'] as String? ?? '',
      startDate: j['start_date'] as String? ?? '',
      endDate: j['end_date'] as String?,
      description: j['description'] as String? ?? '',
      organizers: j['organizers'] as String? ?? '',
      platform: j['platform'] as String? ?? '',
      imgUrl: j['img_url'] as String?,
      themes: j['themes'] as String?,
      prizeAmount: j['prize_amount'] as String?,
      registrationsCount: j['registrations_count'] as int?,
      displayLocation: j['display_location'] as String?,
      featured: j['featured'] as bool?,
      managedByDevpostBadge: j['managed_by_devpost_badge'] as bool?,
      listingActive: j['listing_active'] as bool?,
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
        if (e is Map<String, dynamic>) {
          list.add(parseItem(e));
        }
      }
    }
    return PaginatedResponse(
      items: list,
      total: j['total'] as int? ?? list.length,
      page: j['page'] as int? ?? 1,
      pageSize: j['page_size'] as int? ?? list.length,
      totalPages: j['total_pages'] as int? ?? 1,
    );
  }
}
