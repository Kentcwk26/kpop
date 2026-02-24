import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String announcementTitle;
  final String announcementContent;
  final String announcementImage;
  final String announcementLink;
  final Timestamp createdTime;

  Announcement({
    required this.id,
    required this.announcementTitle,
    required this.announcementContent,
    required this.announcementImage,
    required this.announcementLink,
    required this.createdTime,
  });

  factory Announcement.fromFirestore(Map<String, dynamic> data, String id) {
    return Announcement(
      id: id,
      announcementTitle: data['announcementTitle'] ?? '',
      announcementContent: data['announcementContent'] ?? '',
      announcementImage: data['announcementImage'] ?? '',
      announcementLink: data['announcementLink'] ?? '',
      createdTime: data['createdTime'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'announcementTitle': announcementTitle,
      'announcementContent': announcementContent,
      'announcementImage': announcementImage,
      'announcementLink': announcementLink,
      'createdTime': createdTime,
    };
  }
}