import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/events/data/event_details_modal.dart';

class EventFlowSectionUI extends StatelessWidget {
  final Color color;
  const EventFlowSectionUI({super.key, required this.data, required this.color});

  final EventFlowSection data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title, // "Event flow"
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'SFPRO',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 14),

        // Stack so we can draw the dotted line behind the cards
        Stack(
          children: [
            // Dotted vertical connector line
            Positioned(
              left: 22, // aligns with card padding visually
              top: 18,
              bottom: 18,
              child: _DottedLine(
                color: color, // soft pink dots
                dotRadius: 2,
                gap: 5,
              ),
            ),

            // Cards
            Column(
              children: List.generate(data.steps.length, (i) {
                final step = data.steps[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i == data.steps.length - 1 ? 0 : 14),
                  child: _EventFlowCard(step: step,color: color,),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}

class _EventFlowCard extends StatelessWidget {
  final Color color;
  const _EventFlowCard({required this.step, required this.color});

  final EventFlowStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 21, 19, 23),
      decoration: BoxDecoration(
        color: color, // light pink
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // left content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.timeRange,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'SFPRO',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 37),
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 20,
                    // height: 1.15,
                    fontFamily: 'SFPRO',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // right icon
          Icon(
            step.icon,
            size: 30,
            color: const Color(0xFF111111),
          ),
        ],
      ),
    );
  }
}

/// Simple dotted vertical line (like your screenshot)
class _DottedLine extends StatelessWidget {
  const _DottedLine({
    required this.color,
    this.dotRadius = 2,
    this.gap = 8,
  });

  final Color color;
  final double dotRadius;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final height = c.maxHeight;
        final step = (dotRadius * 2) + gap;
        final count = (height / step).floor();

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return Container(
              width: dotRadius * 2,
              height: dotRadius * 2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        );
      },
    );
  }
}
