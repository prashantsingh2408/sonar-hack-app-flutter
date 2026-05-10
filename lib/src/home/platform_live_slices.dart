const platformLivePageSize = '14';

String addDaysIso(int days) {
  final d = DateTime.now().toUtc().add(Duration(days: days));
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Matches `buildPlatformLiveSliceParams` in `platformLiveSlices.ts`.
Map<String, String> buildPlatformLiveSliceParams(String platform, String sliceId) {
  final p = <String, String>{
    'page': '1',
    'page_size': platformLivePageSize,
    'platform': platform,
  };
  switch (sliceId) {
    case 'featured':
      p['featured'] = 'true';
      p['sort'] = 'end_asc';
      if (platform == 'Devpost') {
        p['venue'] = 'online';
      }
      break;
    case 'active':
      p['status'] = 'Active';
      p['sort'] = 'end_asc';
      break;
    case 'upcoming':
      p['status'] = 'Upcoming';
      p['sort'] = 'end_asc';
      break;
    case 'past':
      p['status'] = 'Past';
      p['sort'] = 'end_desc';
      break;
    case 'active-upcoming':
      p['status'] = 'Active,Upcoming';
      p['sort'] = 'most_relevant';
      break;
    case 'online':
      p['status'] = 'Active';
      p['venue'] = 'online';
      p['sort'] = 'end_asc';
      break;
    case 'in-person':
      p['status'] = 'Active';
      p['venue'] = 'in_person';
      p['sort'] = 'end_asc';
      break;
    case 'top-prizes':
      p['status'] = 'Active,Upcoming';
      p['sort'] = 'prize_amount';
      break;
    case 'trending':
      p['status'] = 'Active';
      p['sort'] = 'registrations_desc';
      break;
    case 'new':
      p['status'] = 'Active,Upcoming';
      p['sort'] = 'recently_added';
      break;
    case 'starting-soon':
      p['status'] = 'Upcoming';
      p['start_date_to'] = addDaysIso(60);
      p['sort'] = 'start_asc';
      break;
    case 'today-launch':
      final today = addDaysIso(0);
      p['status'] = 'Active,Upcoming';
      p['start_date_from'] = today;
      p['start_date_to'] = today;
      p['sort'] = 'start_asc';
      break;
    case 'ai':
      p['status'] = 'Active,Upcoming';
      p['themes'] =
          'Machine Learning/AI,Artificial Intelligence,OpenAI,LLM,LLMs,Gemini,Generative AI';
      p['sort'] = 'most_relevant';
      break;
    case 'active-lte10':
      p['status'] = 'Active';
      p['days_remaining'] = 'lte10';
      p['sort'] = 'end_asc';
      break;
    case 'active-lte30':
      p['status'] = 'Active';
      p['days_remaining'] = 'lte30';
      p['sort'] = 'end_asc';
      break;
    case 'active-1-2mo':
      p['status'] = 'Active';
      p['days_remaining'] = 'gt30,lte60';
      p['sort'] = 'end_asc';
      break;
    case 'active-2-3mo':
      p['status'] = 'Active';
      p['days_remaining'] = 'gt60,lte90';
      p['sort'] = 'end_asc';
      break;
    case 'audience-professional':
      p['status'] = 'Active,Upcoming';
      p['audience'] = 'professional';
      p['sort'] = 'end_asc';
      break;
    case 'audience-students':
      p['status'] = 'Active,Upcoming';
      p['audience'] = 'college_student,graduate_student,high_school';
      p['sort'] = 'end_asc';
      break;
    case 'audience-open':
      p['status'] = 'Active,Upcoming';
      p['audience'] = 'open_to_all';
      p['sort'] = 'end_asc';
      break;
    default:
      p['status'] = 'Active';
      p['sort'] = 'end_asc';
  }
  return p;
}

/// Default slice tabs for “Live on …” bands (same ids as web catalog).
const defaultPlatformLiveSliceTabIds = <String>[
  'featured',
  'active',
  'upcoming',
  'past',
  'active-upcoming',
  'online',
  'top-prizes',
  'trending',
  'new',
  'starting-soon',
  'today-launch',
  'ai',
  'in-person',
  'active-lte10',
  'active-lte30',
  'active-1-2mo',
  'active-2-3mo',
  'audience-professional',
  'audience-students',
  'audience-open',
];

const platformLiveSliceLabels = <String, String>{
  'featured': 'Featured',
  'active': 'Active',
  'upcoming': 'Upcoming',
  'past': 'Past',
  'active-upcoming': 'Live + upcoming',
  'online': 'Online · live',
  'top-prizes': 'Top prizes',
  'trending': 'Most participants',
  'new': 'Recently added',
  'starting-soon': 'Starts within 60d',
  'today-launch': 'Today launch',
  'ai': 'AI & ML',
  'in-person': 'In-person · live',
  'active-lte10': 'Active · ≤10 days',
  'active-lte30': 'Active · ≤1 month',
  'active-1-2mo': 'Active · 1–2 mo to deadline',
  'active-2-3mo': 'Active · 2–3 mo to deadline',
  'audience-professional': 'Professionals · live',
  'audience-students': 'Students · live',
  'audience-open': 'Open to all · live',
};

/// Primary hosts for horizontal “Live on …” bands (web `PLATFORM_LIVE_HOST_TO_CATEGORY_ROW_ID`).
const platformLiveHosts = <String>['Devpost', 'Lablab', 'Hack2skill', 'Hackster', 'Unstop'];
