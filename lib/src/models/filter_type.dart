/// Mirrors `emptyHackathonFilters` / `FilterType` in sonar-hack-app.
class FilterType {
  const FilterType({
    this.platform = const [],
    this.status = const [],
    this.techStack = const [],
    this.stars = const [],
    this.contributors = const [],
    this.daysRemaining = const [],
    this.organizer = '',
    this.interestThemes = const [],
    this.venueModes = const [],
    this.openTo = const [],
    this.managedByDevpost = false,
    this.featuredOnly = false,
    this.startDateFrom = '',
    this.startDateTo = '',
    this.endDateFrom = '',
    this.endDateTo = '',
    this.minPrizeUsd = '',
    this.minParticipants = '',
    this.participantAudience = const [],
    this.audienceIncludeUnknown = false,
    this.multiChipJoin = MultiChipJoin.or,
  });

  final List<String> platform;
  final List<String> status;
  final List<String> techStack;
  final List<String> stars;
  final List<String> contributors;
  final List<String> daysRemaining;
  final String organizer;
  final List<String> interestThemes;
  final List<String> venueModes;
  final List<String> openTo;
  final bool managedByDevpost;
  final bool featuredOnly;
  final String startDateFrom;
  final String startDateTo;
  final String endDateFrom;
  final String endDateTo;
  final String minPrizeUsd;
  final String minParticipants;
  final List<String> participantAudience;
  final bool audienceIncludeUnknown;
  final MultiChipJoin multiChipJoin;

  static const FilterType empty = FilterType();

  FilterType copyWith({
    List<String>? platform,
    List<String>? status,
    List<String>? daysRemaining,
    String? organizer,
    List<String>? interestThemes,
    List<String>? venueModes,
    List<String>? openTo,
    bool? managedByDevpost,
    bool? featuredOnly,
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    String? minPrizeUsd,
    String? minParticipants,
    List<String>? participantAudience,
    bool? audienceIncludeUnknown,
    MultiChipJoin? multiChipJoin,
  }) {
    return FilterType(
      platform: platform ?? List.from(this.platform),
      status: status ?? List.from(this.status),
      techStack: techStack ?? List.from(this.techStack),
      stars: stars ?? List.from(this.stars),
      contributors: contributors ?? List.from(this.contributors),
      daysRemaining: daysRemaining ?? List.from(this.daysRemaining),
      organizer: organizer ?? this.organizer,
      interestThemes: interestThemes ?? List.from(this.interestThemes),
      venueModes: venueModes ?? List.from(this.venueModes),
      openTo: openTo ?? List.from(this.openTo),
      managedByDevpost: managedByDevpost ?? this.managedByDevpost,
      featuredOnly: featuredOnly ?? this.featuredOnly,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
      endDateFrom: endDateFrom ?? this.endDateFrom,
      endDateTo: endDateTo ?? this.endDateTo,
      minPrizeUsd: minPrizeUsd ?? this.minPrizeUsd,
      minParticipants: minParticipants ?? this.minParticipants,
      participantAudience: participantAudience ?? List.from(this.participantAudience),
      audienceIncludeUnknown: audienceIncludeUnknown ?? this.audienceIncludeUnknown,
      multiChipJoin: multiChipJoin ?? this.multiChipJoin,
    );
  }
}

enum MultiChipJoin { or, and }
