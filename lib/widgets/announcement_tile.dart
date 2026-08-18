import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/database/announcement.dart';
import 'package:musbx/database/feedback.dart';
import 'package:musbx/utils/feedback.dart';
import 'package:musbx/widgets/widgets.dart';

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
    this.onResponseSent,
  });

  final Announcement? announcement;
  final bool isUnread;
  final void Function(String response)? onResponseSent;

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
  void dispose() {
    otherFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcement == null) return _buildPlaceholder(context);
    final Announcement announcement = widget.announcement!;

    PersistentValue.preferences.remove(
      "announcements/${announcement.id}/response",
    );

    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              ListenableBuilder(
                listenable: otherFieldController,
                builder: (context, child) => Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed:
                        _selectedResponses.isEmpty ||
                            // Guard for 'Other' being selected but the field empty
                            (_selectedResponses.length == 1 &&
                                _selectedResponses.single == otherFieldName &&
                                otherFieldController.text.trim().isEmpty)
                        ? null
                        : () async {
                            final responses = _selectedResponses
                                .map(
                                  (response) => response == otherFieldName
                                      ? otherFieldController.text.trim()
                                      : response,
                                )
                                .toList();

                            for (final response in responses) {
                              if (response.isEmpty) continue;
                              await UserFeedback.insert(
                                FeedbackEntry(
                                  content: response,
                                  responseTo: announcement.id,
                                ),
                              );
                            }

                            if (context.mounted) {
                              showAlertSnackBar(
                                context,
                                leading: Icon(Symbols.celebration),
                                title: Text("Thank you for your response!"),
                              );
                            }

                            final response = responses.join(", ");

                            setState(() {
                              sentResponse?.value = response;
                            });

                            widget.onResponseSent?.call(response);
                          },
                    child: Text("Submit"),
                  ),
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
        mainAxisSize: MainAxisSize.min,
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
          _selectedResponses = _selectedResponses
              .where((e) => e != response)
              .toList();
        } else if (!_selectedResponses.contains(response)) {
          _selectedResponses = [..._selectedResponses, response];
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
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
