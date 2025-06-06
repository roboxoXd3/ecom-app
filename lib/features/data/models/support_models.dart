import 'package:flutter/widgets.dart';

class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int orderIndex;
  final DateTime createdAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.orderIndex,
    required this.createdAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: json['category'],
      orderIndex: json['order_index'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SupportInfo {
  final String id;
  final String title;
  final String? subtitle;
  final String type;
  final String icon;
  final String? actionType;
  final String? actionValue;
  final String? availability;
  final int orderIndex;
  final DateTime createdAt;

  SupportInfo({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.icon,
    this.actionType,
    this.actionValue,
    this.availability,
    required this.orderIndex,
    required this.createdAt,
  });

  factory SupportInfo.fromJson(Map<String, dynamic> json) {
    return SupportInfo(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      type: json['type'],
      icon: json['icon'],
      actionType: json['action_type'],
      actionValue: json['action_value'],
      availability: json['availability'],
      orderIndex: json['order_index'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  IconData get iconData =>
      IconData(int.parse(icon), fontFamily: 'MaterialIcons');
}
