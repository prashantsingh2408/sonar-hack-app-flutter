/// Sort keys accepted by `/api/hackathons` (mirrors web `hackathonSort.ts`).
const hackathonSortDefault = 'most_relevant';

const hackathonSortOptions = <String>{
  'most_relevant',
  'saved_order',
  'submission_date',
  'recently_added',
  'prize_amount',
  'prize_amount_asc',
  'prize_then_id_desc',
  'prize_then_end_desc',
  'prize_then_start_asc',
  'prize_then_start_desc',
  'id',
  'relevance',
  'active_first',
  'start_asc',
  'start_desc',
  'end_asc',
  'end_desc',
  'title_asc',
  'title_desc',
  'platform_asc',
  'platform_desc',
  'organizers_asc',
  'organizers_desc',
  'registrations_desc',
  'registrations_asc',
};

const secondarySortKeys = <String>{
  'submission_date',
  'start_asc',
  'start_desc',
  'end_asc',
  'end_desc',
  'title_asc',
  'title_desc',
  'platform_asc',
  'platform_desc',
  'organizers_asc',
  'organizers_desc',
  'registrations_desc',
  'registrations_asc',
  'prize_amount',
  'prize_amount_asc',
  'recently_added',
  'id',
};

const maxHackathonSortChain = 12;

bool isHackathonSortValue(String v) => hackathonSortOptions.contains(v);

bool isAllowedHackathonSecondarySort(String v) =>
    isHackathonSortValue(v) && secondarySortKeys.contains(v);

String? resolveHackathonSecondarySort(String primary, String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  if (!isAllowedHackathonSecondarySort(s)) return null;
  if (s == primary) return null;
  return s;
}

List<String> coerceHackathonSortChain(List<String> chain) {
  final out = <String>[];
  final seen = <String>{};
  for (final k in chain) {
    if (k.isEmpty || seen.contains(k)) continue;
    if (!isHackathonSortValue(k)) continue;
    seen.add(k);
    out.add(k);
    if (out.length >= maxHackathonSortChain) break;
  }
  if (out.isEmpty) return [hackathonSortDefault];
  return out;
}
