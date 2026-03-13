import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/database/announcement.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/utils/announcements.dart';

class AnnouncementsPage extends StatelessWidget {
  AnnouncementsPage({super.key});

  final Future<List<Announcement>> _future = Announcements.getAll();

  @override
  Widget build(BuildContext context) {
    final DateTime previousReadAt = Announcements.readAt.value;

    // Mark all announcements as read
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      Announcements.readAt.value = DateTime.now();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Announcements"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            return ListView(
              children: [
                for (Announcement? announcement
                    in snapshot.data ?? [null, null, null])
                  AnnouncementTile(
                    announcement: announcement,
                    isUnread:
                        announcement?.createdAt.toLocal().isAfter(
                          previousReadAt,
                        ) ??
                        false,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AnnouncementTile extends StatelessWidget {
  static const List<String> months = [
    "jan",
    "feb",
    "mar",
    "apr",
    "may",
    "jun",
    "jul",
    "aug",
    "sep",
    "oct",
    "nov",
    "dec",
  ];

  const AnnouncementTile({
    super.key,
    required this.announcement,
    this.isUnread = false,
  });

  final Announcement? announcement;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    String formatDate(DateTime d) =>
        "${d.day} ${months[d.month - 1].toUpperCase()}${d.year != DateTime.now().year ? " ${d.year}" : ""}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

    if (this.announcement == null) return _buildPlaceholder(context);
    final Announcement announcement = this.announcement!;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  announcement.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isUnread)
                  Badge(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                  ),
              ],
            ),
            Text(
              formatDate(announcement.createdAt.toLocal()),
              style: theme.textTheme.labelMedium,
            ),
            MarkdownBody(
              data: announcement.content ?? "",
              softLineBreak: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                blockquoteDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primary,
                ),
                blockquote: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            // Title
            TextPlaceholder(
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // Date
            TextPlaceholder(
              width: 100,
              style: theme.textTheme.labelMedium,
            ),
            // Content
            TextPlaceholder(style: theme.textTheme.bodyMedium),
            TextPlaceholder(style: theme.textTheme.bodyMedium),
            TextPlaceholder(width: 200, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class AnnouncementsButton extends StatelessWidget {
  /// A simple icon button that opens the "Announcements"-page when pressed
  /// and displays the number of unread announcements.
  AnnouncementsButton({super.key});

  /// Whether the tooltip with the title of the latest announcement has been shown.
  static bool hasShownTooltip = false;

  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Announcements.readAt,
      builder: (context, readAt, child) => FutureBuilder(
        future: Announcements.getUnread(),
        builder: (context, snapshot) {
          final List<Announcement> unread = snapshot.data ?? [];

          if (unread.isNotEmpty) {
            if (!hasShownTooltip) {
              hasShownTooltip = true;

              // Open tooltip
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _tooltipKey.currentState?.ensureTooltipVisible();
              });
            }
          }

          return Tooltip(
            key: _tooltipKey,
            triggerMode: TooltipTriggerMode.manual,
            message: unread.firstOrNull?.title ?? "Announcements",
            showDuration: const Duration(seconds: 3),
            child: IconButton(
              onPressed: () {
                context.push(Routes.announcements);
              },
              icon: Badge.count(
                backgroundColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isLabelVisible: unread.isNotEmpty,
                count: unread.length,
                maxCount: 9,
                child: Icon(Symbols.notifications),
              ),
            ),
          );
        },
      ),
    );
  }
}
