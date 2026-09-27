import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final Color color;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
    required this.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'book',
      color: _parseColor(json['color']?.toString()),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  static Color _parseColor(String? value) {
    if (value == null || value.isEmpty) return const Color(0xFF2563EB);
    final hex = value.replaceAll('#', '');
    final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return parsed == null ? const Color(0xFF2563EB) : Color(parsed);
  }

  IconData get iconData {
    switch (icon) {
      case 'landmark':
        return Icons.account_balance_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'handshake':
        return Icons.handshake_rounded;
      case 'file-text':
        return Icons.description_outlined;
      case 'scale':
        return Icons.account_balance_rounded;
      case 'users':
        return Icons.family_restroom_rounded;
      case 'briefcase':
      case 'work':
        return Icons.work_outline_rounded;
      case 'leaf':
      case 'eco':
        return Icons.eco_outlined;
      case 'book':
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  List<Object?> get props => [id, name, slug, icon, color, order];
}
