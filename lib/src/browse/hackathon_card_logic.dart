// Mirrors `sonar-hack-app` card helpers: `utils.ts`, `participantAudience.ts`.
// Keeps browse cards aligned with web HackathonCard.tsx.

import 'package:flutter/material.dart';

import '../models/hackathon.dart';

const _staleNoEndDateDays = 120;
const _hack2skillLongRunwayDays = 45;
const _nearDeadlineMs = 72 * 3600 * 1000;
const _minDaysForMonthStyle = 31;

/// Visible badge bucket for Material styling (maps web Tailwind chip colors).
enum CardStatusTone { neutral, green, amber, blue }

class WhoCanParticipateLine {
  const WhoCanParticipateLine({required this.line, this.title, required this.isFallback});

  final String line;
  final String? title;
  final bool isFallback;
}

bool _isValidHttpUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  try {
    final u = Uri.parse(url.trim());
    return u.scheme == 'https' || u.scheme == 'http';
  } catch (_) {
    return false;
  }
}

String normalizeLablabPublicUrl(String url) {
  final t = url.trim();
  if (t.isEmpty) return '';
  try {
    final u = Uri.parse(t);
    if (!u.host.toLowerCase().contains('lablab.ai')) return t;
    final m = RegExp(r'/(?:ai-hackathons|event)/([^/?#]+)', caseSensitive: false).firstMatch(u.path);
    if (m != null && m.groupCount >= 1) {
      final slug = m.group(1);
      if (slug != null && slug.isNotEmpty) return 'https://lablab.ai/event/$slug';
    }
    return t;
  } catch (_) {
    return t;
  }
}

/// Safe external host URL for CTAs (not our app).
String? hackathonPrimaryExternalUrl(Hackathon hackathon) {
  final raw = hackathon.url.trim();
  if (raw.isEmpty || !_isValidHttpUrl(raw)) return null;
  try {
    final host = Uri.parse(raw).host.replaceFirst(RegExp(r'^www\.'), '').toLowerCase();
    if (host.contains('vercel.app') || host == 'localhost' || host.startsWith('127.')) return null;
    if (host.contains('lablab.ai')) return normalizeLablabPublicUrl(raw);
    return raw;
  } catch (_) {
    return null;
  }
}

/// Devpost challenge `/participants` tab URL when applicable.
String? hackathonParticipantsDirectoryUrl(Hackathon hackathon) {
  final raw = hackathon.url.trim();
  if (raw.isEmpty || !_isValidHttpUrl(raw)) return null;
  try {
    final u = Uri.parse(raw);
    final host = u.host.replaceFirst(RegExp(r'^www\.'), '').toLowerCase();
    if (host.contains('vercel.app') || host == 'localhost' || host.startsWith('127.')) return null;
    if (host.endsWith('.devpost.com') && host != 'devpost.com') {
      return '${u.scheme}://${u.host}/participants';
    }
    return null;
  } catch (_) {
    return null;
  }
}

String normalizeHackathonPlainText(String? s) {
  if (s == null) return '';
  return s
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\r\n|\r|\n'), ' ')
      .replaceAll(RegExp(r'\\n', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\\r', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\\t', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

DateTime? parseLocalDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return null;
  final s = dateStr.trim();
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m != null) {
    final y = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final day = int.tryParse(m.group(3)!);
    if (y == null || mo == null || day == null) return null;
    return DateTime(y, mo, day);
  }
  return DateTime.tryParse(s);
}

int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays.round();
}

DateTime _addOneCalendarMonthLocal(DateTime d) {
  var y = d.year;
  var m = d.month;
  final day = d.day;
  if (m == 12) {
    y += 1;
    m = 1;
  } else {
    m += 1;
  }
  final dim = DateTime(y, m + 1, 0).day;
  final newDay = day > dim ? dim : day;
  return DateTime(y, m, newDay);
}

({int months, int days}) countMonthsAndRemainingDays(DateTime startDay, DateTime endDay) {
  final s = DateTime(startDay.year, startDay.month, startDay.day);
  final e = DateTime(endDay.year, endDay.month, endDay.day);
  if (e.isBefore(s)) return (months: 0, days: 0);
  var months = 0;
  var cur = DateTime(s.year, s.month, s.day);
  for (;;) {
    final next = _addOneCalendarMonthLocal(cur);
    if (!next.isAfter(e)) {
      months += 1;
      cur = next;
    } else {
      break;
    }
  }
  final days = calendarDaysBetween(cur, e);
  return (months: months, days: days);
}

String _formatMonthsAndDaysPhrase(int months, int days) {
  final parts = <String>[];
  if (months > 0) parts.add(months == 1 ? '1 month' : '$months months');
  if (days > 0) parts.add(days == 1 ? '1 day' : '$days days');
  return parts.join(' and ');
}

String _formatMonthsAndDaysPhraseCompact(int months, int days) {
  final parts = <String>[];
  if (months > 0) parts.add(months == 1 ? '1 mo' : '$months mo');
  if (days > 0) parts.add(days == 1 ? '1 d' : '$days d');
  return parts.join(' · ');
}

DateTime? parseHackathonDeadlineInstant(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return null;
  final s = dateStr.trim();
  if (RegExp(r'T\d').hasMatch(s) || RegExp(r'^\d{4}-\d{2}-\d{2}[ T]\d').hasMatch(s)) {
    return DateTime.tryParse(s);
  }
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m != null) {
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final day = int.parse(m.group(3)!);
    return DateTime(y, mo - 1, day, 23, 59, 59, 999);
  }
  return DateTime.tryParse(s);
}

String _formatRemainingToDeadlineMs(int remainingMs) {
  if (remainingMs < 60000) return 'Less than a minute to deadline';
  final totalMinutes = (remainingMs / 60000).ceil();
  if (totalMinutes < 60) {
    return totalMinutes == 1 ? '1 more minute to deadline' : '$totalMinutes more minutes to deadline';
  }
  final hours = remainingMs ~/ 3600000;
  final mins = (remainingMs % 3600000) ~/ 60000;
  if (mins == 0) {
    return hours == 1 ? '1 more hour to deadline' : '$hours more hours to deadline';
  }
  return '$hours h $mins m to deadline';
}

String _formatElapsedSinceDeadlineMs(int elapsedMs) {
  if (elapsedMs < 60000) return 'Just ended';
  final minutes = elapsedMs ~/ 60000;
  if (minutes < 60) {
    return minutes == 1 ? 'Ended 1 minute ago' : 'Ended $minutes minutes ago';
  }
  final hours = elapsedMs ~/ 3600000;
  final mins = (elapsedMs % 3600000) ~/ 60000;
  if (mins == 0) {
    return hours == 1 ? 'Ended 1 hour ago' : 'Ended $hours hours ago';
  }
  return 'Ended $hours h $mins m ago';
}

bool _marketingCopySaysScheduleTba(String titleLc, String descLc, String statusLc) {
  final blob = '$titleLc $descLc $statusLc';
  if (blob.contains('to be announced')) return true;
  if (RegExp(r'dates?\s*(tba|tbd|to be announced)', caseSensitive: false).hasMatch(blob)) return true;
  if (RegExp(r'20\d{2}\s*/\s*tba', caseSensitive: false).hasMatch(blob)) return true;
  if (RegExp(r'(fall|spring|summer|winter)\s+20\d{2}\s*/\s*tba', caseSensitive: false).hasMatch(blob)) {
    return true;
  }
  return false;
}

bool _platLab(String? p) => p != null && p.toLowerCase().contains('lablab');
bool _platDevpost(String? p) =>
    p != null && (p.toLowerCase() == 'devpost' || p.toLowerCase().contains('devpost'));
bool _platHack2skill(String? p) => p != null && p.toLowerCase().contains('hack2skill');
bool _platHackerearth(String? p) =>
    p != null && (p.toLowerCase() == 'hackerearth' || p.toLowerCase().contains('hackerearth'));
bool _platHackster(String? p) => p != null && p.toLowerCase().contains('hackster');
bool _platUnstop(String? p) => p != null && p.toLowerCase().contains('unstop');
bool _platDevfolio(String? p) => p != null && p.toLowerCase().contains('devfolio');

/// Mirrors web `getStatusCategory`.
String _statusCategory(Hackathon hackathon) {
  final s = hackathon.status.toLowerCase().trim();
  final today = DateTime.now();
  final titleLc = hackathon.title.toLowerCase();
  final desc = hackathon.description.toLowerCase();
  final plat = hackathon.platform.trim().toLowerCase();
  final orgLc = hackathon.organizers.toLowerCase();
  final isLabLab = _platLab(plat);

  final end = parseLocalDate(hackathon.endDate);
  final start = parseLocalDate(hackathon.startDate);

  if (!isLabLab && hackathon.listingActive == false) {
    return 'Past';
  }

  if (_platHack2skill(plat)) {
    final blob = '$desc $s $orgLc';
    if (blob.contains('registration closed') ||
        RegExp(r'registration\s+is\s+closed').hasMatch(blob) ||
        RegExp(r'sign\s*ups?\s+closed').hasMatch(blob)) {
      return 'Past';
    }
  }

  if (isLabLab && (end != null || start != null)) {
    if (end != null && calendarDaysBetween(DateTime(today.year, today.month, today.day), end) < 0) {
      return 'Past';
    }
    if (start != null && calendarDaysBetween(DateTime(today.year, today.month, today.day), start) > 0) {
      return 'Upcoming';
    }
    if (hackathon.listingActive == false) return 'Past';
  } else if (isLabLab && hackathon.listingActive == false) {
    return 'Past';
  }

  if (end != null &&
      calendarDaysBetween(DateTime(today.year, today.month, today.day),
              DateTime(end.year, end.month, end.day)) <
          0) {
    return 'Past';
  }

  if (start != null &&
      calendarDaysBetween(DateTime(today.year, today.month, today.day),
              DateTime(start.year, start.month, start.day)) >
          0) {
    return 'Upcoming';
  }

  if (_platHack2skill(plat) && end != null) {
    final daysToEnd = calendarDaysBetween(DateTime(today.year, today.month, today.day),
        DateTime(end.year, end.month, end.day));
    if (daysToEnd > _hack2skillLongRunwayDays) {
      final noStart = start == null;
      final startStillFuture =
          start != null &&
              calendarDaysBetween(DateTime(today.year, today.month, today.day),
                      DateTime(start.year, start.month, start.day)) >
                  0;
      if (noStart || startStillFuture) return 'Upcoming';
    }
  }

  if (end == null &&
      start != null &&
      calendarDaysBetween(DateTime(start.year, start.month, start.day),
              DateTime(today.year, today.month, today.day)) >
          _staleNoEndDateDays) {
    return 'Past';
  }

  if (s.contains('tba') || _marketingCopySaysScheduleTba(titleLc, desc, s)) {
    return 'Upcoming';
  }

  if (s.contains('closed') ||
      s.contains('finished') ||
      s.contains('past') ||
      s.contains('completed') ||
      s.trim() == 'ended' ||
      RegExp(r'\bended\b').hasMatch(s)) {
    return 'Past';
  }

  final isHackerEarth = _platHackerearth(plat);
  if (isHackerEarth && end == null && start == null && (s == 'live' || s == 'upcoming')) {
    return 'Past';
  }
  if (s == 'previous' || s == 'ended') return 'Past';
  if (s == 'live') return 'Active';
  if (s == 'upcoming') return 'Upcoming';
  if (s.contains('upcoming') || s.contains('soon')) return 'Upcoming';
  if (s.contains('active') || s.contains('open') || s.contains('ongoing')) return 'Active';

  if (isLabLab &&
      end == null &&
      start == null &&
      !(s.contains('tba') || _marketingCopySaysScheduleTba(titleLc, desc, s))) {
    return 'Upcoming';
  }
  return 'Active';
}

/// Mirrors web `getStatusDisplay` label + tone.
({String label, CardStatusTone tone}) cardStatusPresentation(Hackathon hackathon) {
  final category = _statusCategory(hackathon);
  final plat = hackathon.platform;
  final rawLc = hackathon.status.toLowerCase().trim();
  final titleLc = hackathon.title.toLowerCase();
  final descLc = hackathon.description.toLowerCase();

  if (category == 'Past') {
    if (_platLab(plat)) return (label: 'Finished', tone: CardStatusTone.neutral);
    if (_platDevpost(plat) || _platDevfolio(plat)) return (label: 'Ended', tone: CardStatusTone.neutral);
    if (_platHackster(plat)) return (label: 'Ended', tone: CardStatusTone.neutral);
    if (_platUnstop(plat)) return (label: 'Ended', tone: CardStatusTone.neutral);
    if (_platHack2skill(plat)) return (label: 'Closed', tone: CardStatusTone.neutral);
    return (label: 'Past', tone: CardStatusTone.neutral);
  }

  if (category == 'Active') {
    if (_platHackerearth(plat) || _platLab(plat)) return (label: 'Live', tone: CardStatusTone.green);
    if (_platDevpost(plat) ||
        _platDevfolio(plat) ||
        _platHack2skill(plat) ||
        _platHackster(plat) ||
        _platUnstop(plat)) {
      return (label: 'Open', tone: CardStatusTone.green);
    }
    return (label: 'Active', tone: CardStatusTone.green);
  }

  if (_platLab(plat)) {
    if (rawLc.contains('tba') || _marketingCopySaysScheduleTba(titleLc, descLc, rawLc)) {
      return (label: 'TBA', tone: CardStatusTone.amber);
    }
    if (rawLc.contains('register')) return (label: 'Register', tone: CardStatusTone.blue);
    return (label: 'Upcoming', tone: CardStatusTone.blue);
  }
  if (_platDevpost(plat) ||
      _platDevfolio(plat) ||
      _platHackster(plat) ||
      _platUnstop(plat)) {
    return (label: 'Upcoming', tone: CardStatusTone.blue);
  }
  if (_platHack2skill(plat)) return (label: 'Upcoming', tone: CardStatusTone.blue);
  return (label: 'Upcoming', tone: CardStatusTone.blue);
}

ColorPair chipColorsForTone(CardStatusTone tone, ColorScheme scheme) {
  switch (tone) {
    case CardStatusTone.neutral:
      return ColorPair(bg: scheme.surfaceContainerHighest, fg: scheme.onSurfaceVariant);
    case CardStatusTone.green:
      return ColorPair(bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534));
    case CardStatusTone.amber:
      return ColorPair(bg: const Color(0xFFFEF3C7), fg: const Color(0xFF78350F));
    case CardStatusTone.blue:
      return ColorPair(bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1E40AF));
  }
}

class ColorPair {
  const ColorPair({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

String formatHackathonDateRangeUi(Hackathon hackathon) {
  String part(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final d = parseLocalDate(raw.trim());
    if (d == null) return raw.trim();
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  final s = part(hackathon.startDate);
  final e = part(hackathon.endDate);
  return '$s - $e';
}

String? getHackathonDeadlineHint(Hackathon hackathon) {
  final today = DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  final start = parseLocalDate(hackathon.startDate);
  final end = parseLocalDate(hackathon.endDate);
  final deadlineInstant = parseHackathonDeadlineInstant(hackathon.endDate);

  if (deadlineInstant != null) {
    final remainingMs = deadlineInstant.difference(DateTime.now()).inMilliseconds;
    if (remainingMs > 0 && remainingMs < _nearDeadlineMs) {
      return _formatRemainingToDeadlineMs(remainingMs);
    }
    if (remainingMs <= 0 && remainingMs > -_nearDeadlineMs) {
      return _formatElapsedSinceDeadlineMs(-remainingMs);
    }
  }

  if (end != null) {
    final endDay = DateTime(end.year, end.month, end.day);
    final daysToEnd = calendarDaysBetween(todayDay, endDay);
    if (daysToEnd > 1) {
      if (daysToEnd >= _minDaysForMonthStyle) {
        final md = countMonthsAndRemainingDays(todayDay, endDay);
        final phrase = _formatMonthsAndDaysPhrase(md.months, md.days);
        if (phrase.isNotEmpty) return '$phrase to deadline';
      }
      return '$daysToEnd more days to deadline';
    }
    if (daysToEnd == 1) return '1 more day to deadline';
    if (daysToEnd == 0) return 'Deadline today';
    final ago = -daysToEnd;
    if (ago == 1) return 'Ended yesterday';
    if (ago >= _minDaysForMonthStyle) {
      final md = countMonthsAndRemainingDays(endDay, todayDay);
      final phrase = _formatMonthsAndDaysPhrase(md.months, md.days);
      if (phrase.isNotEmpty) return 'Ended $phrase ago';
    }
    return 'Ended $ago days ago';
  }

  if (start != null) {
    final startDay = DateTime(start.year, start.month, start.day);
    final daysToStart = calendarDaysBetween(todayDay, startDay);
    if (daysToStart > 1) {
      if (daysToStart >= _minDaysForMonthStyle) {
        final md = countMonthsAndRemainingDays(todayDay, startDay);
        final phrase = _formatMonthsAndDaysPhrase(md.months, md.days);
        if (phrase.isNotEmpty) return 'Starts in $phrase';
      }
      return 'Starts in $daysToStart days';
    }
    if (daysToStart == 1) return 'Starts tomorrow';
    if (daysToStart == 0) return 'Starts today';
    final ago = -daysToStart;
    if (ago == 1) return 'Started yesterday';
    if (ago >= _minDaysForMonthStyle) {
      final md = countMonthsAndRemainingDays(startDay, todayDay);
      final phrase = _formatMonthsAndDaysPhrase(md.months, md.days);
      if (phrase.isNotEmpty) return 'Started $phrase ago';
    }
    if (ago > 1) return 'Started $ago days ago';
  }

  return null;
}

String? getHackathonRunLengthLabelCompact(Hackathon hackathon) {
  final start = parseLocalDate(hackathon.startDate);
  final end = parseLocalDate(hackathon.endDate);
  if (start == null || end == null) return null;
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  final between = calendarDaysBetween(startDay, endDay);
  if (between < 0) return null;
  if (between >= _minDaysForMonthStyle) {
    final md = countMonthsAndRemainingDays(startDay, endDay);
    final phrase = _formatMonthsAndDaysPhraseCompact(md.months, md.days);
    if (phrase.isEmpty) return null;
    return phrase;
  }
  final inclusive = between + 1;
  return inclusive == 1 ? '1 day' : '$inclusive days';
}

int? hackathonSubmissionWindowDays(Hackathon hackathon) {
  final start = parseLocalDate(hackathon.startDate);
  final end = parseLocalDate(hackathon.endDate);
  if (start == null || end == null) return null;
  return calendarDaysBetween(start, end);
}

String? submissionPeriodNote(Hackathon hackathon) {
  final span = hackathonSubmissionWindowDays(hackathon);
  if (span == null || span < 0) return null;
  final plat = hackathon.platform.toLowerCase();
  final isDevpost = plat.contains('devpost');
  if (span >= 400) {
    return isDevpost
        ? 'Long submission window from Devpost (may not be a multi-year event).'
        : 'Very long date range; may be a registration or submission window, not event dates.';
  }
  if (isDevpost && span >= 120) {
    return 'Dates are the submission period from Devpost.';
  }
  return null;
}

List<String> splitThemeLabels(String? themes, {int max = 8}) {
  if (themes == null || themes.trim().isEmpty) return [];
  return themes
      .split(RegExp(r'[,|]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .take(max)
      .toList();
}

String? formatPrizeDisplayLine(String? prize) {
  final raw = prize?.trim();
  if (raw == null || raw.isEmpty) return null;
  final plain = raw.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (plain.isEmpty) return null;
  if (RegExp(r'in prizes', caseSensitive: false).hasMatch(plain) ||
      RegExp(r'prizes?$', caseSensitive: false).hasMatch(plain)) {
    return plain;
  }
  return '$plain in prizes';
}

bool isLikelyOnlineLocation(String loc) {
  return RegExp(r'^\s*online\s*$', caseSensitive: false).hasMatch(loc.trim());
}

const _audienceLabels = <String, String>{
  'open_to_all': 'Open to all',
  'high_school': 'High school',
  'college_student': 'College / undergrad',
  'graduate_student': 'Graduate / PhD',
  'professional': 'Working professional',
  'freelancer': 'Freelancer / independent',
  'developer': 'Developers',
};

String participantAudienceLabelsCsv(String? tagsCsv) {
  if (tagsCsv == null || tagsCsv.trim().isEmpty) return '';
  final labels = tagsCsv
      .split(',')
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .map((t) => _audienceLabels[t] ?? t)
      .toList();
  return labels.join(' · ');
}

WhoCanParticipateLine formatWhoCanParticipateForCard(Hackathon h) {
  final raw = h.whoCanParticipate?.trim();
  if (raw != null && raw.isNotEmpty) {
    const max = 240;
    final truncated = raw.length > max;
    final line = truncated ? '${raw.substring(0, max - 1)}…' : raw;
    return WhoCanParticipateLine(line: line, title: truncated ? raw : null, isFallback: false);
  }
  final tagsLine = participantAudienceLabelsCsv(h.participantAudienceTags);
  if (tagsLine.isNotEmpty) {
    return WhoCanParticipateLine(line: tagsLine, title: tagsLine, isFallback: false);
  }
  if (h.inviteOnly == true) {
    return const WhoCanParticipateLine(
      line: 'Invite only — host approval may be required.',
      isFallback: false,
    );
  }
  return const WhoCanParticipateLine(
    line: 'Not in our index yet — open the host page for full “Who can participate” rules.',
    title:
        'Eligibility details are loaded when available from the platform. Use the host link below for age, student, and location rules.',
    isFallback: true,
  );
}
