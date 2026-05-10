import '../models/filter_type.dart';
import '../models/hackathon.dart';

/// Mirrors `hackathonHomeSections.ts` tiers (subset — uses `status` + platform heuristics).
enum HomeRelevanceTier {
  featuredDevpost,
  liveDevpost,
  lablab,
  hack2skill,
  hackerearth,
  more,
  past,
}

const homeSectionOrder = <HomeRelevanceTier>[
  HomeRelevanceTier.featuredDevpost,
  HomeRelevanceTier.liveDevpost,
  HomeRelevanceTier.lablab,
  HomeRelevanceTier.hack2skill,
  HomeRelevanceTier.hackerearth,
  HomeRelevanceTier.more,
  HomeRelevanceTier.past,
];

const tierLabels = <HomeRelevanceTier, String>{
  HomeRelevanceTier.featuredDevpost: 'Featured on Devpost',
  HomeRelevanceTier.liveDevpost: 'Live on Devpost',
  HomeRelevanceTier.lablab: 'Live on LabLab.ai',
  HomeRelevanceTier.hack2skill: 'Active on Hack2skill',
  HomeRelevanceTier.hackerearth: 'Live on HackerEarth',
  HomeRelevanceTier.more: 'More hackathons',
  HomeRelevanceTier.past: 'Past and ended',
};

String _statusBucket(Hackathon h) {
  final s = h.status.toLowerCase();
  if (s.contains('past') || s.contains('ended') || s.contains('closed')) return 'Past';
  if (s.contains('upcoming')) return 'Upcoming';
  return 'Active';
}

HomeRelevanceTier hackathonHomeRelevanceTier(Hackathon h) {
  final cat = _statusBucket(h);
  final pl = h.platform.toLowerCase();
  if (cat == 'Past') return HomeRelevanceTier.past;
  final isDevpost = pl.contains('devpost');
  final devpostPick = h.featured == true || h.managedByDevpostBadge == true;
  if (isDevpost && devpostPick) return HomeRelevanceTier.featuredDevpost;
  if (isDevpost && (cat == 'Active' || cat == 'Upcoming')) return HomeRelevanceTier.liveDevpost;
  if (pl.contains('lablab') && cat == 'Active') return HomeRelevanceTier.lablab;
  if (pl.contains('hack2skill') && cat == 'Active') return HomeRelevanceTier.hack2skill;
  if (pl.contains('hackerearth') && cat == 'Active') return HomeRelevanceTier.hackerearth;
  return HomeRelevanceTier.more;
}

bool hackathonHasChipFilters(FilterType f) {
  return f.platform.isNotEmpty ||
      f.status.isNotEmpty ||
      f.daysRemaining.isNotEmpty ||
      f.organizer.trim().isNotEmpty ||
      f.interestThemes.isNotEmpty ||
      f.venueModes.isNotEmpty ||
      f.openTo.isNotEmpty ||
      f.managedByDevpost ||
      f.startDateFrom.trim().isNotEmpty ||
      f.startDateTo.trim().isNotEmpty ||
      f.endDateFrom.trim().isNotEmpty ||
      f.endDateTo.trim().isNotEmpty ||
      f.minPrizeUsd.trim().isNotEmpty ||
      f.minParticipants.trim().isNotEmpty ||
      f.participantAudience.isNotEmpty ||
      f.audienceIncludeUnknown ||
      f.featuredOnly;
}

bool shouldShowCuratedHomeSections({
  required FilterType filters,
  required String search,
  required List<String> sortChain,
}) {
  final primary = sortChain.isEmpty ? 'most_relevant' : sortChain.first;
  return primary == 'most_relevant' &&
      search.trim().isEmpty &&
      !hackathonHasChipFilters(filters);
}

List<MapEntry<HomeRelevanceTier, List<Hackathon>>> groupHackathonsByHomeTier(List<Hackathon> items) {
  final buckets = <HomeRelevanceTier, List<Hackathon>>{
    for (final t in homeSectionOrder) t: [],
  };
  for (final h in items) {
    buckets[hackathonHomeRelevanceTier(h)]!.add(h);
  }
  final out = <MapEntry<HomeRelevanceTier, List<Hackathon>>>[];
  for (final t in homeSectionOrder) {
    final list = buckets[t]!;
    if (list.isNotEmpty) out.add(MapEntry(t, list));
  }
  return out;
}
