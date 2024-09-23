import 'package:flutter/material.dart';

class MySettingsListTile extends StatelessWidget {
  final String title;
  final Widget action;
  final Color color;
  final Color textColor;

  const MySettingsListTile({
    super.key,
    required this.title,
    required this.action,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(left: 25, top: 10, right: 25),
      padding: const EdgeInsets.only(left: 25, right: 25, top: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // title
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),

          // action
          action
        ],
      ),
    );
  }
}
