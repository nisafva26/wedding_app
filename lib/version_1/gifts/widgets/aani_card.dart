import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AaniCard extends StatelessWidget {
  const AaniCard({
    super.key,

    this.onCopied,
    required this.name,
    required this.phoneNumber,
  });

  final String name;
  final String phoneNumber;

  /// optional callback: (label, value)
  final void Function(String label, String value)? onCopied;

  @override
  Widget build(BuildContext context) {
    const bg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6A0D3A), Color(0xFF7B1242), Color(0xFF5B0A31)],
      stops: [0.0, 0.55, 1.0],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: const BoxDecoration(color: Color(0xFF771549)),
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 32,
        ).copyWith(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Section(
              label: "Name",
              value: name,
              isCopyable: true,
              onCopy: () => _copy(context, "Name", name),
            ),
            SizedBox(height: 20),
            const _DividerLine(),
            SizedBox(height: 20),
            _Section(
              label: "Phone number",
              value: phoneNumber,
              isCopyable: true,
              onCopy: () => _copy(context, "Phone number", phoneNumber),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    onCopied?.call(label, value);

    // Optional subtle feedback (remove if you don’t want it)
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xff771549),
          content: Text(
            "$label copied",
            style: TextStyle(color: Colors.white, fontFamily: 'SFPRO'),
          ),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.value,
    required this.isCopyable,
    required this.onCopy,
  });

  final String label;
  final String value;
  final bool isCopyable;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontFamily: 'SFPRO',
      fontWeight: FontWeight.w400,
    );

    final valueStyle = const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontFamily: "SFPRO",

      fontWeight: FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          // Use Flexible instead of Expanded
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 6),
              Text(value, style: valueStyle, maxLines: 4),
            ],
          ),
        ),

        if (isCopyable) ...[
          const SizedBox(width: 10),
          _CopyButton(onTap: onCopy),
        ],
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Icon(
        Icons.copy_rounded,
        size: 22,
        color: Colors.white.withOpacity(0.95),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      color: Colors.white.withOpacity(0.14),
    );
  }
}
