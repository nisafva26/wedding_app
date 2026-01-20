import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/dashbaord/widgets/wave_seperator.dart';
import 'package:wedding_invite/version_1/waves/wave_seperator_helper.dart';

class PremiumExpandableSection extends StatefulWidget {
  final String title;
  final String? countText;
  final Widget collapsedPreview;
  final Widget expandedContent;
  final bool initiallyExpanded;
  final Color previousSectionColor; // The color of the section ABOVE
  final Color currentSectionColor; // The color of THIS section
  final Color iconColor;
  final Color sectionColor;
  final Color nextSectionColor;
  final Function(bool isExpanded)? onExpansionChanged;
  final Color titleColor;

  const PremiumExpandableSection({
    super.key,
    required this.title,
    this.countText,
    required this.collapsedPreview,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.iconColor = const Color(0xFF06471D),
    required this.previousSectionColor,
    required this.currentSectionColor,
    required this.sectionColor,
    required this.nextSectionColor,
    this.onExpansionChanged,
    this.titleColor = const Color(0xFF06471D),
  });

  @override
  State<PremiumExpandableSection> createState() =>
      _PremiumExpandableSectionState();
}

class _PremiumExpandableSectionState extends State<PremiumExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isExpanded = widget.initiallyExpanded;
    });
  }

  void _handleTap() {
    setState(() => _isExpanded = !_isExpanded);
    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(_isExpanded);
    }

    // Notify the parent so it can scroll
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // This ensures there's no gap during animation
      color: widget.currentSectionColor,
      child: Column(
        children: [
          // 1. THE WAVE (Transitions from Previous Color to Current Color)
          WaveSeparator(
            topColor: widget.previousSectionColor,
            bottomColor: widget.currentSectionColor,
          ),

          //  TopWaveSeparator(
          //   topColor: widget.previousSectionColor,
          //   bottomColor: widget.currentSectionColor,
          // ),

          // 2. HEADER
          GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style:  TextStyle(
                      color: widget.titleColor,
                      fontSize: 32,
                      fontFamily: 'Montage',
                    ),
                  ),
                  const Spacer(),
                  if (widget.countText != null && _isExpanded)
                    Text(
                      widget.countText!,
                      style: const TextStyle(
                        color: Color(0xFF1F4D35),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.arrow_downward, color: widget.iconColor),
                  ),
                ],
              ),
            ),
          ),

          // 3. CONTENT
          // AnimatedCrossFade(
          //   firstChild: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 20),
          //     child: widget.collapsedPreview,
          //   ),
          //   secondChild: widget.expandedContent,
          //   crossFadeState: _isExpanded
          //       ? CrossFadeState.showSecond
          //       : CrossFadeState.showFirst,
          //   duration: const Duration(milliseconds: 400),
          //   sizeCurve: Curves.easeInOutCubic,
          // ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: widget.collapsedPreview,
            ),
            secondChild: widget.expandedContent,
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            // 1. Increase duration slightly for a more "premium" weighted feel
            duration: const Duration(milliseconds: 600),

            // 2. Add these curves to slow down the entering/exiting children
            // This makes the "Return" animation follow the same smooth path as the "Expand"
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,

            // 3. Keep the size change smooth
            sizeCurve: Curves.easeInOutCubic,
          ),
          const SizedBox(height: 20),

          // ✅ BOTTOM WAVE: current -> next
          // BottomWaveSeparator(
          //   topColor: widget.currentSectionColor,
          //   bottomColor: widget.nextSectionColor,
          // ),
        ],
      ),
    );
  }
}
