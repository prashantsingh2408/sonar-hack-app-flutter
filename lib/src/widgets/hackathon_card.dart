import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../browse/hackathon_card_logic.dart';
import '../models/hackathon.dart';
import 'app_icons.dart';

/// Wishlist heart parity with web — supply when signed in so POST `/api/me/wishlist` runs.
class WishlistBinding {
  WishlistBinding({required this.contains, required this.toggle});

  final bool Function(int hackathonId) contains;
  final Future<void> Function(int hackathonId) toggle;
}

/// Browse/hackathon rail card aligned with web `HackathonCard.tsx` (meta rows + footer actions).
class HackathonCard extends StatelessWidget {
  const HackathonCard({
    super.key,
    required this.hackathon,
    this.wishlist,
    this.onOpenDetail,
    this.maxDescriptionChars = 200,
    this.themeChipLimit = 8,
  });

  final Hackathon hackathon;
  final WishlistBinding? wishlist;
  /// When set, tap opens in-app detail (web `/hackathon/[slug]` parity); otherwise opens external host URL.
  final ValueChanged<Hackathon>? onOpenDetail;
  final int maxDescriptionChars;
  final int themeChipLimit;

  Future<void> _openExternal(BuildContext context, String url) async {
    final u = Uri.tryParse(url);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryUrl = hackathonPrimaryExternalUrl(hackathon) ?? hackathon.url.trim();
    final platformHostUrl =
        primaryUrl.isNotEmpty ? primaryUrl : null;

    final status = cardStatusPresentation(hackathon);
    final statusColors = chipColorsForTone(status.tone, scheme);

    final deadlineHint = getHackathonDeadlineHint(hackathon);
    final prizeLine = formatPrizeDisplayLine(hackathon.prizeAmount);
    final loc = hackathon.displayLocation?.trim();
    final locIcon = loc != null && loc.isNotEmpty && !isLikelyOnlineLocation(loc)
        ? Icons.location_on_rounded
        : Icons.public_rounded;

    final participantsUrl = hackathonParticipantsDirectoryUrl(hackathon);
    final rc = hackathon.registrationsCount;
    final whoCan = formatWhoCanParticipateForCard(hackathon);
    final descPlain = normalizeHackathonPlainText(hackathon.description);
    final descPreview = descPlain.length > maxDescriptionChars
        ? '${descPlain.substring(0, maxDescriptionChars - 1)}…'
        : descPlain.isEmpty
            ? 'No description available.'
            : descPlain;

    final runLen = getHackathonRunLengthLabelCompact(hackathon);
    final schedNote = submissionPeriodNote(hackathon);
    final themes = splitThemeLabels(hackathon.themes, max: themeChipLimit);

    final onSurfaceMuted = scheme.onSurfaceVariant;
    final wl = wishlist;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {
          if (onOpenDetail != null) {
            onOpenDetail!(hackathon);
            return;
          }
          if (platformHostUrl != null) {
            _openExternal(context, platformHostUrl);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: hackathon.imgUrl != null && hackathon.imgUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: hackathon.imgUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: scheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Icon(AppIcons.search, color: scheme.outline),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: scheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image_rounded, color: scheme.outline),
                          ),
                        )
                      : Container(
                          color: scheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child:
                              Icon(Icons.emoji_events_rounded, size: 48, color: scheme.primary.withValues(alpha: 0.35)),
                        ),
                ),
                if (hackathon.featured == true)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.85)),
                        color: scheme.surface.withValues(alpha: 0.95),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'FEATURED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hackathon.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColors.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: statusColors.fg,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (deadlineHint != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 13, color: Colors.teal.shade800),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  deadlineHint,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: const Color(0xFF065F46),
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (loc != null && loc.isNotEmpty) ...[
                    _MetaBlock(
                      icon: locIcon,
                      iconColor: onSurfaceMuted,
                      child: Text(loc, style: _cardMetaStyle(context, muted: false)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (prizeLine != null) ...[
                    const SizedBox(height: 8),
                    _MetaBlock(
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFD97706),
                      child: Text(
                        prizeLine,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                  if (rc != null && rc.isFinite) ...[
                    const SizedBox(height: 8),
                    _MetaBlock(
                      icon: Icons.groups_rounded,
                      iconColor: scheme.primary,
                      child: participantsUrl != null
                          ? InkWell(
                              onTap: () => _openExternal(context, participantsUrl),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: NumberFormat.decimalPattern('en_US').format(rc.round()),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                            color: scheme.primary,
                                          ),
                                    ),
                                    TextSpan(
                                      text: ' participants',
                                      style: TextStyle(
                                        color: onSurfaceMuted,
                                        fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: NumberFormat.decimalPattern('en_US').format(rc.round()),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: ' participants',
                                    style: TextStyle(color: onSurfaceMuted, fontSize: Theme.of(context).textTheme.bodySmall?.fontSize),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _MetaBlock(
                    icon: Icons.assignment_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Who can participate: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: whoCan.line,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: whoCan.isFallback ? onSurfaceMuted : scheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hackathon.organizers.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _MetaBlock(
                      icon: Icons.business_rounded,
                      iconColor: onSurfaceMuted,
                      child: Text(
                        hackathon.organizers,
                        style: _cardMetaStyle(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _MetaBlock(
                    icon: Icons.calendar_today_rounded,
                    iconColor: onSurfaceMuted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatHackathonDateRangeUi(hackathon), style: _cardMetaStyle(context)),
                        if (runLen != null) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Text(
                              'Length: $runLen',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onSurfaceMuted),
                            ),
                          ),
                        ],
                        if (schedNote != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            schedNote,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFFB45309),
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (themes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.sell_outlined, size: 15, color: onSurfaceMuted),
                        ),
                        ...themes.map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                              color: scheme.primaryContainer.withValues(alpha: 0.35),
                            ),
                            child: Text(
                              t,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hackathon.managedByDevpostBadge == true) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: scheme.secondaryContainer,
                        ),
                        child: Text(
                          'Devpost managed',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSecondaryContainer,
                              ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    descPreview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: scheme.onSurface,
                        ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (platformHostUrl != null)
                    IconButton(
                      tooltip: 'View on ${hackathon.platform}',
                      icon: Icon(Icons.open_in_new_rounded, color: scheme.onSurfaceVariant),
                      onPressed: () => _openExternal(context, platformHostUrl),
                    ),
                  if (wl != null)
                    IconButton(
                      tooltip: wl.contains(hackathon.id) ? 'Remove from wishlist' : 'Add to wishlist',
                      icon: Icon(
                        wl.contains(hackathon.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: wl.contains(hackathon.id) ? Colors.redAccent : scheme.onSurfaceVariant,
                      ),
                      onPressed: () => wl.toggle(hackathon.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _cardMetaStyle(BuildContext context, {bool muted = true}) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
        color: muted ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
        height: 1.35,
      );
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}
