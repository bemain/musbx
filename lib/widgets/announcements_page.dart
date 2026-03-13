import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_plus/material_plus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:musbx/database/announcement.dart';
import 'package:musbx/navigation.dart';
import 'package:musbx/utils/announcements.dart';

class AnnouncementsPage extends StatelessWidget {
  AnnouncementsPage({super.key});

  final Future<List<Announcement>> future = Announcements.getAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Announcements"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            return SegmentedCard(
              children: [
                for (Announcement announcement in snapshot.data!)
                  AnnouncementTile(announcement: announcement),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AnnouncementTile extends StatelessWidget {
  const AnnouncementTile({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      title: Text(announcement.title),
      subtitle: Text(announcement.content ?? ""),
    );
  }
}

class AnnouncementsButton extends StatelessWidget {
  /// A simple icon button that opens the "Announcements"-page when pressed
  /// and displays the number of unread announcements.
  const AnnouncementsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Announcements.getUnread(),
      builder: (context, snapshot) {
        final List<Announcement> unread = snapshot.data ?? [];

        return IconButton(
          onPressed: () {
            context.push(Routes.announcements);
          },
          icon: Badge(
            backgroundColor: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            isLabelVisible: unread.isNotEmpty,
            label: Text(unread.length.toString()),
            child: Icon(Symbols.notifications),
          ),
        );
      },
    );
  }
}
