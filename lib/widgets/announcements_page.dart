import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/database/announcement.dart';
import 'package:musbx/database/feedback.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/settings/settings_page.dart';
import 'package:musbx/utils/announcements.dart';
import 'package:musbx/utils/feedback.dart';
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
                                icon: Icon(Symbols.campaign),
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
                                          return _buildInfoDialog(context);
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

  AlertDialog _buildInfoDialog(BuildContext context) {
    return AlertDialog(
      title: Text("Give feedback"),
      icon: Icon(Symbols.campaign),
      content: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium,
          children: [
            TextSpan(
              text:
                  """Let us know what you think about Musician's Toolbox! What works well? What could we do better? Your feedback is invaluable to us in developing the app for the future.

Do not send any personal details here. Remember that we cannot respond to your feedback directly; if you want a response, please contact the developer via """,
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

class AnnouncementTile extends StatefulWidget {
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
  State<AnnouncementTile> createState() => _AnnouncementTileState();
}

class _AnnouncementTileState extends State<AnnouncementTile> {
  /// The currently selected responses.
  /// The special value '[otherFieldName]' signifies that the 'Other' option is
  /// selected, and the value of [otherFieldController] should be used.
  List<String> _selectedResponses = [];
  TextEditingController otherFieldController = TextEditingController();
  static const otherFieldName = "__other__";

  late final PersistentValue<String>? sentResponse =
      widget.announcement == null
      ? null
      : PersistentValue<String>(
          "announcements/${widget.announcement!.id}/response",
          initialValue: "",
        );

  String formatDate(DateTime d) =>
      "${d.day} ${AnnouncementTile.months[d.month - 1].toUpperCase()}${d.year != DateTime.now().year ? " ${d.year}" : ""}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    if (widget.announcement == null) return _buildPlaceholder(context);
    final Announcement announcement = widget.announcement!;

    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
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
                if (widget.isUnread)
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
            _markdownText(context, announcement.content ?? ""),

            // Already sent response
            if (sentResponse?.value.isEmpty == false) ...[
              SizedBox(height: 4),
              Text(
                "You responded:",
                style: Theme.of(context).textTheme.labelMedium,
              ),
              _markdownText(context, sentResponse?.value ?? ""),
            ],

            // Available responses
            if (announcement.responses != null &&
                sentResponse?.value.isEmpty == true) ...[
              _buildResponses(context, announcement),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _selectedResponses.isEmpty
                      ? null
                      : () {
                          final responses = _selectedResponses.map(
                            (response) => response == otherFieldName
                                ? otherFieldController.text
                                : response,
                          );

                          for (final response in responses) {
                            UserFeedback.insert(
                              FeedbackEntry(
                                content: response,
                                responseTo: announcement.id,
                              ),
                            );
                          }

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
                                  Text("Thank you for your response!"),
                                ],
                              ),
                            ),
                          );

                          setState(() {
                            sentResponse?.value = responses.join(", ");
                          });
                        },
                  child: Text("Submit"),
                ),
              ),
            ],
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
          horizontal: 16,
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

  Widget _markdownText(BuildContext context, String text) {
    final ThemeData theme = Theme.of(context);
    final MarkdownStyleSheet styleSheet = MarkdownStyleSheet.fromTheme(theme)
        .copyWith(
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
        );
    return MarkdownBody(
      data: text,
      softLineBreak: true,
      styleSheet: styleSheet,
    );
  }

  Widget _buildResponses(BuildContext context, Announcement announcement) {
    return announcement.responses?.allowMultiple == true
        ? _buildResponsesMulti(context, announcement)
        : _buildResponsesSingle(context, announcement);
  }

  Widget _buildResponsesSingle(
    BuildContext context,
    Announcement announcement,
  ) {
    return RadioGroup<String>(
      groupValue: _selectedResponses.firstOrNull,
      onChanged: (value) {
        setState(() {
          _selectedResponses = value == null ? [] : [value];
        });
      },
      child: Column(
        children: [
          for (String response in announcement.responses!.responses)
            RadioListTile(
              value: response,
              contentPadding: EdgeInsets.all(0),
              title: _markdownText(context, response),
            ),
          if (announcement.responses?.showOther == true)
            RadioListTile(
              value: otherFieldName,
              contentPadding: EdgeInsets.all(0),
              title: TextField(
                controller: otherFieldController,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                ),
                onTap: () {
                  setState(() {
                    _selectedResponses = [otherFieldName];
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsesMulti(
    BuildContext context,
    Announcement announcement,
  ) {
    void onChanged(bool? value, String response) {
      setState(() {
        if (value == false) {
          _selectedResponses.remove(response);
        } else if (!_selectedResponses.contains(response)) {
          _selectedResponses.add(response);
        }
      });
    }

    return Column(
      children: [
        for (String response in announcement.responses!.responses)
          ListTile(
            onTap: () =>
                onChanged(!_selectedResponses.contains(response), response),
            leading: Checkbox(
              value: _selectedResponses.contains(response),
              onChanged: (value) => onChanged(value, response),
            ),
            title: _markdownText(context, response),
          ),
        if (announcement.responses?.showOther == true)
          ListTile(
            onTap: () => onChanged(
              !_selectedResponses.contains(otherFieldName),
              otherFieldName,
            ),
            leading: Checkbox(
              value: _selectedResponses.contains(otherFieldName),
              onChanged: (value) => onChanged(value, otherFieldName),
            ),
            title: TextField(
              controller: otherFieldController,
              decoration: InputDecoration(
                border: UnderlineInputBorder(),
              ),
              onTap: () => onChanged(true, otherFieldName),
            ),
          ),
      ],
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
                child: Icon(Symbols.campaign), // or 'campaign'?
              ),
            ),
          );
        },
      ),
    );
  }
}
