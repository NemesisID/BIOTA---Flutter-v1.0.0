import 'package:flutter/material.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final String shortDescription;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String organizer;
  final String category;
  final int maxParticipants;
  final int currentParticipants;
  final String registrationUrl;
  final bool isFree;
  final double? price;
  final String requirements;
  final List<String> tags;
  final String contactInfo;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.organizer,
    required this.category,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.registrationUrl,
    required this.isFree,
    this.price,
    required this.requirements,
    required this.tags,
    required this.contactInfo,
  });

  bool get isRegistrationOpen => DateTime.now().isBefore(startDate) && currentParticipants < maxParticipants;
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isPast => DateTime.now().isAfter(endDate);
  
  String get statusText {
    if (isPast) return 'Selesai';
    if (isOngoing) return 'Berlangsung';
    if (isUpcoming) return 'Akan Datang';
    return 'Unknown';
  }

  Color get statusColor {
    if (isPast) return Colors.grey;
    if (isOngoing) return Colors.green;
    if (isUpcoming) return Colors.blue;
    return Colors.grey;
  }
}