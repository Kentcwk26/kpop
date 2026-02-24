import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../models/eventsActivities.dart';
import '../repositories/announcement_repository.dart';
import '../utils/date_formatter.dart';
import '../viewmodels/notification_viewmodel.dart';

/// =====================
/// PROVIDERS
/// =====================

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) => AnnouncementRepository());

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncements();
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<Notifications>>((ref) {
  return NotificationsNotifier();
});

/// =====================
/// NOTIFICATION NOTIFIER
/// =====================

class NotificationsNotifier extends StateNotifier<List<Notifications>> {
  NotificationsNotifier() : super([]) {
    _listen();
  }

  final NotificationViewModel _vm = NotificationViewModel();

  void _listen() {
    _vm.streamNotifications().listen(
      (data) {
        state = data;
      },
      onError: (err) {
        print("Stream error: $err");
      },
    );
  }

  Future<void> deleteNotification(String id) async {
    await _vm.deleteNotification(id);
  }

  Future<void> markAsRead(String id) async {
    await _vm.markAsRead(id);
  }

  Future<void> markAsUnread(String id) async {
    await _vm.markAsUnread(id);
  }
}

/// =====================
/// MAIN SCREEN
/// =====================

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: CustomScrollView(
        slivers: [

          SliverToBoxAdapter(
            child: announcementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading announcements: $e')),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No announcements yet."),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(
                      title: 'Announcements',
                      icon: Icons.announcement,
                    ),
                    ... announcements.map((announcement) {
                    return AnnouncementListItem(
                      announcement: announcement,
                      onTap: () {
                        _showAnnouncementDetails(context, announcement);
                      },
                    );
                  }).toList(),
                  ]
                );
              },
            ),
          ),

          /// NOTIFICATIONS
          SliverToBoxAdapter(
            child: notifications.isEmpty
                ? const _SectionHeader(
                    title: 'Notifications',
                    icon: Icons.notifications,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'Notifications',
                        icon: Icons.notifications,
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return _NotificationListItem(
                            notification: n,
                            onDismiss: () => ref
                                .read(notificationsProvider.notifier)
                                .deleteNotification(n.notificationId),
                            onStatusToggle: () {
                              if (n.status == "Unread") {
                                ref.read(notificationsProvider.notifier).markAsRead(n.notificationId);
                              } else {
                                ref.read(notificationsProvider.notifier).markAsUnread(n.notificationId);
                              }
                            },
                            onDelete: () => ref.read(notificationsProvider.notifier).deleteNotification(n.notificationId),
                            onTap: () => _showNotificationDetails(context, n),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// =====================
  /// DIALOGS
  /// =====================

  static void _showNotificationDetails(BuildContext context, Notifications notification) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  static void _showAnnouncementDetails(BuildContext context, Announcement announcement) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.announcementTitle,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (announcement.announcementImage.isNotEmpty)
                  Image.network(
                    announcement.announcementImage,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 16),
                Text(announcement.announcementContent),
                const SizedBox(height: 16),
                if (announcement.announcementLink.isNotEmpty)
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(announcement.announcementLink),
                    ),
                    child: Text(
                      announcement.announcementLink,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================
/// UI COMPONENTS
/// =====================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class AnnouncementListItem extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const AnnouncementListItem({
    required this.announcement,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: onTap,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: announcement.announcementImage.isNotEmpty
                ? Image.network(
                    announcement.announcementImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/empty_pic.jpg',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
          ),
          title: Text(
            announcement.announcementTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormatter.formatDateTime(announcement.createdTime),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _NotificationListItem extends StatelessWidget {
  final Notifications notification;
  final VoidCallback onDismiss;
  final VoidCallback onStatusToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _NotificationListItem({
    required this.notification,
    required this.onDismiss,
    required this.onStatusToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Dismissible(
        key: Key(notification.notificationId),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDismiss(),
        child: Card(
          child: ListTile(
            leading: Icon(
              Icons.notifications,
              color: notification.status == "Read"
                  ? Colors.grey
                  : Colors.red,
            ),
            title: Text(notification.title),
            subtitle: Text(DateFormatter.formatDateTime(notification.dateformat)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}