import 'package:flutter/material.dart';

class AssetTile extends StatelessWidget {
  final String image, title, subtitle, status;
  final Color color;

  const AssetTile({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.asset(image, width: 40),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Chip(
          label: Text(status),
          backgroundColor: color.withOpacity(0.2),
        ),
      ),
    );
  }
}
