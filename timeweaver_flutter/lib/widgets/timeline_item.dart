import 'package:flutter/material.dart';

import '../models/event_item.dart';
import 'event_card.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.event,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onNavigate,
    this.onShare,
    this.onCopy,
  });

  final EventItem event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onNavigate;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF003528),
              ),
            ),
            Container(width: 2, height: 104, color: const Color(0xFFE4D8CA)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: EventCard(
              event: event,
              onEdit: onEdit,
              onDelete: onDelete,
              onDuplicate: onDuplicate,
              onNavigate: onNavigate,
              onShare: onShare,
              onCopy: onCopy,
            ),
          ),
        ),
      ],
    );
  }
}
