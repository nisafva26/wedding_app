import 'package:flutter/material.dart';

class EventGalleryPreviewCard extends StatelessWidget {
  final VoidCallback onViewAll;
  final VoidCallback onAdd;

  const EventGalleryPreviewCard({
    super.key,
    required this.onViewAll,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('View all')),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Placeholder preview
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) {
                return Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.photo, color: Colors.black38),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
