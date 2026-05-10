/// Mirrors web `slugifyHackathonTitle` for `/hackathon/{slug}` and GET `/api/hackathons/by-slug`.
const _slugMax = 80;

String slugifyHackathonTitle(String title) {
  var s = title.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'-{2,}'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  if (s.length > _slugMax) {
    s = s.substring(0, _slugMax);
  }
  s = s.replaceAll(RegExp(r'-+$'), '');
  return s.isEmpty ? 'hackathon' : s;
}
