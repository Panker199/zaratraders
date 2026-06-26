import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Returns a human-readable time string like "2 min ago", "1 hour ago", "Yesterday", etc.
String timeAgo(dynamic timestamp) {
  if (timestamp == null) return '';
  final DateTime dt;
  if (timestamp is Timestamp) {
    dt = timestamp.toDate();
  } else if (timestamp is DateTime) {
    dt = timestamp;
  } else {
    return '';
  }
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month}/${dt.day}/${dt.year}';
}

/// Returns a time string like "10:30 AM"
String formatTime(dynamic timestamp) {
  if (timestamp == null) return '';
  final DateTime dt;
  if (timestamp is Timestamp) {
    dt = timestamp.toDate();
  } else if (timestamp is DateTime) {
    dt = timestamp;
  } else {
    return '';
  }
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final min = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$min $ampm';
}

/// Returns a date header string like "Today", "Yesterday", or "June 24, 2026"
String dateHeader(dynamic timestamp) {
  if (timestamp == null) return '';
  final DateTime dt;
  if (timestamp is Timestamp) {
    dt = timestamp.toDate();
  } else if (timestamp is DateTime) {
    dt = timestamp;
  } else {
    return '';
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDate = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(msgDate).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
}

String _monthName(int m) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[m - 1];
}

/// Generates a color from a string (for avatar backgrounds)
Color colorFromString(String s) {
  final hash = s.codeUnits.fold<int>(0, (h, c) => h * 31 + c);
  const colors = [
    Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFF00BCD4), Color(0xFFE91E63),
    Color(0xFF3F51B5), Color(0xFF009688), Color(0xFFFF5722),
    Color(0xFF607D8B), Color(0xFF795548), Color(0xFFCDDC39),
  ];
  return colors[hash.abs() % colors.length];
}

/// Returns initials from a name (e.g., "John Doe" → "JD")
String initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return parts[0][0].toUpperCase();
}
