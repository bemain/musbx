import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/database/announcement.dart';
import 'package:musbx/database/feedback.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/settings/settings_page.dart';
import 'package:musbx/utils/announcements.dart';
import 'package:musbx/utils/feedback.dart';
import 'package:musbx/widgets/announcement_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementsPage extends StatelessWidget {
  AnnouncementsPage({super.key});

  final Future<List<Announcement>> _future = Announcements.getAll();

  final TextEditingController feedbackController = TextEditingController();

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
        padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint("[Announcements] ${snapshot.error}");

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Symbols.error,
                          size: 96,
                        ),
                        Text(
                          "Failed to load announcements. Please try again later.",
                          textAlign: TextAlign.center,
                        ),
                      ],
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: feedbackController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                icon: Icon(Symbols.feedback),
                                labelText: "Give feedback",
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                            ),
                          ),
                          ListenableBuilder(
                            listenable: feedbackController,
                            builder: (context, child) =>
                                feedbackController.text.isNotEmpty
                                ? SizedBox()
                                : IconButton(
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (context) {
                                          return _buildFeedbackInfoDialog(
                                            context,
                                          );
                                        },
                                      );
                                    },
                                    icon: Icon(Symbols.info),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ListenableBuilder(
                  listenable: feedbackController,
                  builder: (context, child) => IconButton.filled(
                    onPressed: feedbackController.text.isEmpty
                        ? null
                        : () {
                            UserFeedback.insert(
                              FeedbackEntry(content: feedbackController.text),
                            );
                            feedbackController.clear();
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  showCloseIcon: true,
                                  content: Row(
                                    children: [
                                      Icon(
                                        Symbols.celebration,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onInverseSurface,
                                      ),
                                      SizedBox(width: 12),
                                      Text("Thank you for your feedback!"),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                    icon: Icon(Symbols.send),
                    padding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AlertDialog _buildFeedbackInfoDialog(BuildContext context) {
    return AlertDialog(
      title: Text("Give feedback"),
      icon: Icon(Symbols.feedback),
      content: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium,
          children: [
            TextSpan(
              text:
                  """Let us know what you think about Musician's Toolbox! What works well? What could we do better? Your feedback is invaluable to us in developing the app for the future.

Do not send any personal details here. Remember that we cannot respond to your feedback directly; if you want a response please contact the developer via """,
            ),
            TextSpan(
              text: "email",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(developerEmail);
                },
            ),
            TextSpan(text: "."),
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

          if (unread.isNotEmpty && !hasShownTooltip) {
            hasShownTooltip = true;

            // TODO: Maybe show all unread popups, with a button to cycle them
            final Announcement? popup = unread
                .where((a) => a.popup)
                .firstOrNull;

            if (popup != null) {
              // Show polls as popups to get more attention
              SchedulerBinding.instance.addPostFrameCallback((_) {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        child: SingleChildScrollView(
                          child: AnnouncementTile(
                            announcement: popup,
                            isUnread: true,
                            onResponseSent: (response) {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );

                Announcements.readAt.value = popup.createdAt;
              });
            } else {
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
                child: Icon(Symbols.campaign),
              ),
            ),
          );
        },
      ),
    );
  }
}
