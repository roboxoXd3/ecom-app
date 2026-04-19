import 'package:flutter/widgets.dart';
class FAQ {
  String? id;
  String? title;
  String? subtitle;
  String? type;
  String? icon;
  String? actionType;
  String? actionValue;
  int? orderIndex;
  DateTime? createdAt;

  FAQ({
    this.id,
    this.title,
    this.subtitle,
    this.type,
    this.icon,
    this.actionType,
    this.actionValue,
    this.orderIndex,
    this.createdAt,
  });

  FAQ.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    subtitle = json['subtitle'];
    type = json['type'];
    icon = json['icon'];
    actionType = json['action_type'];
    actionValue = json['action_value'];
    orderIndex = json['order_index'];
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['title'] = title;
    data['subtitle'] = subtitle;
    data['type'] = type;
    data['icon'] = icon;
    data['action_type'] = actionType;
    data['action_value'] = actionValue;
    data['order_index'] = orderIndex;
    data['created_at'] = createdAt?.toIso8601String();
    return data;
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
