import '../models/filter_type.dart';
import 'hackathon_sort.dart';

/// Shared browser → `/api/hackathons` query builder (matches `hackathonListQueryParams.ts`).
class BuildHackathonListParamsInput {
  BuildHackathonListParamsInput({
    required this.filters,
    required this.searchTerm,
    required this.sortChain,
    required this.page,
    required this.pageSize,
  });

  final FilterType filters;
  final String searchTerm;
  final List<String> sortChain;
  final int page;
  final int pageSize;
}

Map<String, String> hackathonFiltersToUpstreamQuery(FilterType filters) {
  final themes = filters.interestThemes.where((e) => e.isNotEmpty).join(',');
  final venue = filters.venueModes
      .map((m) {
        if (m == 'Online') return 'online';
        if (m == 'In-person') return 'in_person';
        return '';
      })
      .where((e) => e.isNotEmpty)
      .join(',');
  final openTo = filters.openTo
      .map((x) {
        if (x == 'Public') return 'public';
        if (x == 'Invite only') return 'invite_only';
        return '';
      })
      .where((e) => e.isNotEmpty)
      .join(',');
  final audience = filters.participantAudience.where((e) => e.isNotEmpty).join(',');
  return {
    'themes': themes,
    'venue': venue,
    'openTo': openTo,
    'managedByDevpost': filters.managedByDevpost ? 'true' : 'false',
    'audience': audience,
    'audienceIncludeUnknown': filters.audienceIncludeUnknown ? 'true' : 'false',
  };
}

final _knownDeadlineBands = <String>{
  'lte10',
  'lte20',
  'lte30',
  'lte60',
  'lte90',
  'gt10',
  'gt20',
  'gt30',
  'gt60',
  'tba',
  '0-10',
  '11-20',
  '21-25',
  '26-30',
  '31+',
};

const _canonStatuses = ['Upcoming', 'Active', 'Past'];

String? _canonicalStatusLabel(String s) {
  final t = s.trim();
  for (final x in _canonStatuses) {
    if (x.toLowerCase() == t.toLowerCase()) return x;
  }
  return null;
}

bool _searchQueryImpliesActiveHackathons(String searchQuery) {
  final s = searchQuery.toLowerCase().trim();
  if (s.isEmpty) return false;
  if (RegExp(r'\bnot\s+active\b').hasMatch(s) ||
      RegExp(r'\bnon[-\s]?active\b').hasMatch(s) ||
      RegExp(r'\binactive\b').hasMatch(s)) {
    return false;
  }
  if (RegExp(r'\bnot\s+ended\b').hasMatch(s) ||
      RegExp(r'\bnot\s+closed\b').hasMatch(s) ||
      RegExp(r'\bnon[-\s]?ended\b').hasMatch(s)) {
    return true;
  }
  if (RegExp(r'\bpast\b').hasMatch(s) ||
      RegExp(r'\bended\b').hasMatch(s) ||
      RegExp(r'\bwas\s+active\b').hasMatch(s) ||
      RegExp(r'\bpreviously\s+active\b').hasMatch(s)) {
    return false;
  }
  if (RegExp(r'\bactive\b').hasMatch(s) ||
      RegExp(r'\bactiv\b').hasMatch(s) ||
      RegExp(r'\bongoing\b').hasMatch(s) ||
      RegExp(r'\bstill\s+running\b').hasMatch(s) ||
      RegExp(r'\bstill\s+open\b').hasMatch(s) ||
      RegExp(r'\bcurrently\s+open\b').hasMatch(s)) {
    return true;
  }
  if (RegExp(r'\blive\b').hasMatch(s) && RegExp(r'\bhackathon').hasMatch(s)) return true;
  return false;
}

List<String> mergeActiveStatusHintIntoStatuses(List<String>? current, String searchQuery) {
  final base = (current ?? [])
      .map(_canonicalStatusLabel)
      .whereType<String>()
      .toList();
  if (!_searchQueryImpliesActiveHackathons(searchQuery)) return base;
  final set = {...base};
  if (set.contains('Past')) return base;
  if (!set.contains('Active')) {
    return [...base, 'Active'];
  }
  return base;
}

String normalizeMonthDeadlinePhrasing(String raw) {
  var s = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  s = s.replaceAll(RegExp(r'\bfewer\s+than\b'), 'less than');
  s = s.replaceAllMapped(RegExp(r'\bunder\s+(\d+)\s*(month|months)\b'), (m) => 'less than ${m[1]} ${m[2]}');
  s = s.replaceAllMapped(RegExp(r'\bover\s+(\d+)\s*(month|months)\b'), (m) => 'more than ${m[1]} ${m[2]}');
  s = s.replaceAll(RegExp(r'\bless\s+than\s+'), 'less than ');
  s = s.replaceAll(RegExp(r'\bmore\s+than\s+'), 'more than ');
  s = s.replaceAllMapped(RegExp(r'\bless\s+(\d+)\s*(month|months)\b'), (m) => 'less than ${m[1]} ${m[2]}');
  s = s.replaceAllMapped(RegExp(r'\bmore\s+(\d+)\s*(month|months)\b'), (m) => 'more than ${m[1]} ${m[2]}');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _lteBandFromMonthsCeiling(int n) {
  if (!n.isFinite || n < 1) return null;
  if (n <= 1) return 'lte30';
  if (n == 2) return 'lte60';
  return 'lte90';
}

String? _gtBandFromMonthsExclusiveLower(int n) {
  if (!n.isFinite || n < 1) return null;
  if (n <= 1) return 'gt30';
  if (n == 2) return 'gt60';
  return 'gt60';
}

List<String> inferDeadlineBandsFromSearchQuery(String searchQuery) {
  final s = normalizeMonthDeadlinePhrasing(searchQuery);
  if (s.isEmpty) return [];

  final mentionsComparativeWindow =
      RegExp(r'\b(?:more|greater)\s+than\s+\d+\s*(?:month|months)\b').hasMatch(s) ||
          RegExp(r'\bless\s+than\s+\d+\s*(?:month|months)\b').hasMatch(s) ||
          RegExp(r'\bbetween\s+\d+\s*(?:month|months)\s+and\s+\d+\s*(?:month|months)\b').hasMatch(s) ||
          RegExp(r'\bfrom\s+\d+\s*(?:month|months)\s+to\s+\d+\s*(?:month|months)\b').hasMatch(s) ||
          RegExp(r'\bat\s+least\s+\d+\s*(?:month|months)\b').hasMatch(s) ||
          RegExp(r'\bat\s+most\s+\d+\s*(?:month|months)\b').hasMatch(s);

  if (RegExp(r'\b(month|months)[-\s]*long\b').hasMatch(s) && !mentionsComparativeWindow) return [];
  if (RegExp(r'\bruns?\s+for\s+\d+\s*(?:month|months)\b').hasMatch(s) && !mentionsComparativeWindow) {
    return [];
  }

  final between = RegExp(r'\bbetween\s+(\d+)\s*(?:month|months)\s+and\s+(\d+)\s*(?:month|months)\b').firstMatch(s);
  if (between != null) {
    final a = int.tryParse(between.group(1) ?? '') ?? 0;
    final b = int.tryParse(between.group(2) ?? '') ?? 0;
    final lo = a < b ? a : b;
    final hi = a > b ? a : b;
    final gt = _gtBandFromMonthsExclusiveLower(lo);
    final lte = _lteBandFromMonthsCeiling(hi);
    if (gt != null && lte != null) return [gt, lte];
  }

  final fromTo = RegExp(r'\bfrom\s+(\d+)\s*(?:month|months)\s+to\s+(\d+)\s*(?:month|months)\b').firstMatch(s);
  if (fromTo != null) {
    final a = int.tryParse(fromTo.group(1) ?? '') ?? 0;
    final b = int.tryParse(fromTo.group(2) ?? '') ?? 0;
    final lo = a < b ? a : b;
    final hi = a > b ? a : b;
    final gt = _gtBandFromMonthsExclusiveLower(lo);
    final lte = _lteBandFromMonthsCeiling(hi);
    if (gt != null && lte != null) return [gt, lte];
  }

  String? gt;
  String? lte;

  final mMore = RegExp(r'\b(?:more|greater)\s+than\s+(\d+)\s*(?:month|months)\b').firstMatch(s);
  if (mMore != null) gt = _gtBandFromMonthsExclusiveLower(int.tryParse(mMore.group(1) ?? '') ?? 0);

  final mAtLeast = RegExp(r'\bat\s+least\s+(\d+)\s*(?:month|months)\b').firstMatch(s);
  if (mAtLeast != null) gt = _gtBandFromMonthsExclusiveLower(int.tryParse(mAtLeast.group(1) ?? '') ?? 0);

  final mLess = RegExp(r'\bless\s+than\s+(\d+)\s*(?:month|months)\b').firstMatch(s);
  if (mLess != null) lte = _lteBandFromMonthsCeiling(int.tryParse(mLess.group(1) ?? '') ?? 0);

  final mAtMost = RegExp(r'\bat\s+most\s+(\d+)\s*(?:month|months)\b').firstMatch(s);
  if (mAtMost != null) lte = _lteBandFromMonthsCeiling(int.tryParse(mAtMost.group(1) ?? '') ?? 0);

  if (gt != null && lte != null) return [gt, lte];
  if (gt != null) return [gt];
  if (lte != null) return [lte];
  return [];
}

List<String> mergeDeadlineBandsFromSearchQuery(List<String>? current, String searchQuery) {
  final base = (current ?? [])
      .map((x) => x.trim())
      .where((b) => _knownDeadlineBands.contains(b))
      .toList();
  if (base.isNotEmpty) return base;
  return inferDeadlineBandsFromSearchQuery(searchQuery).where((b) => _knownDeadlineBands.contains(b)).toList();
}

String compactSearchAfterPlatformFilters(String query, List<String>? platforms) {
  final q = query.trim();
  if (q.isEmpty || platforms == null || platforms.isEmpty) return q;

  final pl = platforms.map((p) => p.toLowerCase()).toSet();
  var s = q;

  void strip(RegExp re) {
    s = s.replaceAll(re, ' ');
  }

  if (pl.contains('devpost')) {
    strip(RegExp(r'\b(?:for|on|at|from|of|in|over)\s+dev-?post\b', caseSensitive: false));
    strip(RegExp(r'\bdev-?post\b', caseSensitive: false));
  }
  if (pl.contains('lablab')) {
    strip(RegExp(r'\b(?:for|on|at|from)\s+lab\s*lab\b', caseSensitive: false));
    strip(RegExp(r'\blab\s*lab(?:\.ai)?\b', caseSensitive: false));
    strip(RegExp(r'\blablab(?:\.ai)?\b', caseSensitive: false));
  }
  if (pl.contains('mlh')) {
    strip(RegExp(r'\b(?:for|on)\s+mlh\b', caseSensitive: false));
    strip(RegExp(r'\bmajor\s+league\s+hacking\b', caseSensitive: false));
    strip(RegExp(r'\bmlh\b', caseSensitive: false));
  }
  if (pl.contains('hack2skill')) {
    strip(RegExp(r'\b(?:for|on)\s+hack-?2-?skill\b', caseSensitive: false));
    strip(RegExp(r'\bhack-?2-?skill\b', caseSensitive: false));
    strip(RegExp(r'\bhack2skill\b', caseSensitive: false));
  }
  if (pl.contains('hackerearth')) {
    strip(RegExp(r'\b(?:for|on)\s+hacker\s*earth\b', caseSensitive: false));
    strip(RegExp(r'\bhackerearth\b', caseSensitive: false));
    strip(RegExp(r'\bhacker\s*earth\b', caseSensitive: false));
  }

  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String compactListSearchForApi(String raw, List<String> statusEff, List<String>? platforms) {
  var s = compactSearchAfterPlatformFilters(raw, platforms);
  final st = statusEff.map((x) => x.toLowerCase()).toSet();
  if (st.contains('active')) {
    s = s.replaceAll(RegExp(r'\bactiv\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bactive\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bongoing\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bstill\s+running\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bstill\s+open\b', caseSensitive: false), ' ');
  }
  if (st.contains('upcoming')) {
    s = s.replaceAll(RegExp(r'\bupcoming\b', caseSensitive: false), ' ');
  }
  if (st.contains('past')) {
    s = s.replaceAll(RegExp(r'\bpast\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bended\b', caseSensitive: false), ' ');
  }
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String stripEncodedSmartSearchNoise(String searchTerm, FilterType filters) {
  var s = searchTerm;
  final aud = filters.participantAudience;
  if (aud.any((a) => a == 'professional')) {
    s = s.replaceAll(RegExp(r'\bprofessionals?\b', caseSensitive: false), ' ');
  }
  final days = filters.daysRemaining;
  if (days.isNotEmpty) {
    s = s.replaceAll(RegExp(r'\bbetween\s+\d+\s+(?:to|-|and)\s+\d+\s*months?\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\b\d+\s+(?:to|-|–)\s*\d+\s*months?\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bmonths?\s+or\s+more\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\bor\s+more\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\b\d+\s+months?\s+or\s+more\b', caseSensitive: false), ' ');
  }
  if (filters.startDateFrom.trim().isNotEmpty) {
    s = s.replaceAll(
      RegExp(
        r'\b(?:that\s+)?(?:start|starts|starting|started|open|opens|opening|opened|begin|begins|beginning|began|registration\s+opens?)(?:\s+or\s+(?:start|starts|open|opens|begin|begins))*\s+after\s+(?:the\s+month\s+(?:of\s+)?)?(?:january|february|march|april|may|june|july|august|september|october|november|december)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    s = s.replaceAll(
      RegExp(
        r'\bafter\s+(?:the\s+month\s+(?:of\s+)?)?(?:january|february|march|april|may|june|july|august|september|october|november|december)\b',
        caseSensitive: false,
      ),
      ' ',
    );
  }
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Returns query string map for `Uri.replace(queryParameters: ...)`.
Map<String, String> buildHackathonListParamsFromState(BuildHackathonListParamsInput input) {
  final filters = input.filters;
  final params = <String, String>{
    'page': '${input.page}',
    'page_size': '${input.pageSize}',
  };

  final q0 = input.searchTerm.trim();

  final platformEff = List<String>.from(filters.platform);
  if (RegExp(r'\bdev-?post\b', caseSensitive: false).hasMatch(q0) &&
      !platformEff.any((p) => p.toLowerCase() == 'devpost')) {
    platformEff.add('Devpost');
  }
  if (platformEff.isNotEmpty) {
    params['platform'] = platformEff.join(',');
  }

  final statusEff = mergeActiveStatusHintIntoStatuses(filters.status, q0);
  if (statusEff.isNotEmpty) {
    params['status'] = statusEff.join(',');
  }

  final daysEff = mergeDeadlineBandsFromSearchQuery(filters.daysRemaining, q0);
  if (daysEff.isNotEmpty) {
    params['days_remaining'] = daysEff.join(',');
  }

  final org = filters.organizer.trim();
  if (org.isNotEmpty) params['organizer'] = org;

  final extra = hackathonFiltersToUpstreamQuery(filters);
  if (extra['themes']!.isNotEmpty) params['themes'] = extra['themes']!;
  if (extra['venue']!.isNotEmpty) params['venue'] = extra['venue']!;
  if (extra['openTo']!.isNotEmpty) params['open_to'] = extra['openTo']!;
  if (extra['managedByDevpost'] == 'true') params['managed_by_devpost'] = 'true';
  if (extra['audience']!.isNotEmpty) params['audience'] = extra['audience']!;
  if (extra['audienceIncludeUnknown'] == 'true') {
    params['audience_include_unknown'] = 'true';
  }
  if (filters.multiChipJoin == MultiChipJoin.and) {
    params['chip_join'] = 'and';
  }

  final sf = filters.startDateFrom.trim();
  final st = filters.startDateTo.trim();
  final ef = filters.endDateFrom.trim();
  final et = filters.endDateTo.trim();
  if (_isoDate.hasMatch(sf)) params['start_date_from'] = sf;
  if (_isoDate.hasMatch(st)) params['start_date_to'] = st;
  if (_isoDate.hasMatch(ef)) params['end_date_from'] = ef;
  if (_isoDate.hasMatch(et)) params['end_date_to'] = et;

  final pm = int.tryParse(filters.minPrizeUsd.trim());
  if (pm != null && pm > 0) params['prize_min_usd'] = '$pm';

  final mr = int.tryParse(filters.minParticipants.trim());
  if (mr != null && mr > 0) params['min_registrations'] = '$mr';

  if (filters.featuredOnly) params['featured'] = 'true';

  final chain = coerceHackathonSortChain(List.from(input.sortChain));
  params['sort'] = chain.first;
  if (chain.length > 1) {
    params['sort_chain'] = chain.join(',');
    params['sort2'] = chain[1];
  }

  final q = compactListSearchForApi(
    stripEncodedSmartSearchNoise(q0, filters),
    statusEff,
    platformEff.isEmpty ? null : platformEff,
  );
  if (q.isNotEmpty) params['search'] = q;

  return params;
}
