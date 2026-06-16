import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String? _selectedEventId;
  int? _selectedTemplateIndex; // Tracks which template is active
  bool _sending = false;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // Premium Palette
  static const Color primaryDeep = Color(0xFF6B1139);
  static const Color background = Color(0xFFFCF8F2);
  static const Color accentGold = Color(0xFFB0773B);
  static const Color cardBg = Colors.white;
  static const String fontFamily =
      'SFPRO'; // Ensure this matches your pubspec.yaml

  final _templates = const [
    _NotiTemplate(
      label: "🎬 Event Starting",
      title: "Event is starting",
      body: "Please take your seats — we’re about to begin.",
    ),
    _NotiTemplate(
      label: "📍 Gathering",
      title: "Please come to the main area",
      body: "We’re gathering everyone now. See you there!",
    ),
    _NotiTemplate(
      label: "🍽️ Food Ready",
      title: "Food counter is open",
      body: "Dinner is now being served. Enjoy!",
    ),
    _NotiTemplate(
      label: "📸 Photos",
      title: "Photosession is open",
      body: "Photos are live now — feel free to join the queue!",
    ),
    _NotiTemplate(
      label: "👋 Greetings",
      title: "Stage is open",
      body: "The couple is ready for greetings. Please proceed to the stage.",
    ),
    _NotiTemplate(
      label: "⏰ Reminder",
      title: "Quick Reminder",
      body: "Just a friendly nudge to check the event schedule.",
    ),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selectedEventId == null) {
      _showCustomToast("Please select an event target", isError: true);
      return;
    }
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showCustomToast("Message cannot be empty", isError: true);
      return;
    }

    setState(() => _sending = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendCustomEventNotification',
      );
      final res = await callable.call({
        'weddingId': widget.weddingId,
        'eventId': _selectedEventId,
        'title': title,
        'body': body,
      });

      _showCustomToast(
        "Broadcast Sent! (${(res.data as Map)['tokens']} users)",
      );
    } catch (e) {
      _showCustomToast("Failed to send notification", isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showCustomToast(String msg, {bool isError = false}) {
    final bgColor = isError
        ? const Color(0xFFD64545) // controlled red
        : const Color(0xFFEDE5D8); // soft warm surface

    final textColor = isError
        ? Colors.white
        : const Color(0xFF2E2A27); // your main text color

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(20),
      
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          "BROADCAST",
          style: TextStyle(
            fontFamily: fontFamily,
            letterSpacing: 1.5,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: background,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RECIPIENTS", style: _labelStyle),
                  const SizedBox(height: 12),
                  _EventDropdown(
                    weddingId: widget.weddingId,
                    value: _selectedEventId,
                    onChanged: (v) => setState(() => _selectedEventId = v),
                  ),
                  const SizedBox(height: 32),

                  const Text("QUICK TEMPLATES", style: _labelStyle),
                  const SizedBox(height: 12),
                  // Wrap replaces ListView to show all items without scrolling
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_templates.length, (index) {
                      final isSelected = _selectedTemplateIndex == index;
                      return _TemplateChip(
                        template: _templates[index],
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedTemplateIndex = index;
                            _titleCtrl.text = _templates[index].title;
                            _bodyCtrl.text = _templates[index].body;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  const Text("MESSAGE CONTENT", style: _labelStyle),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _titleCtrl,
                    label: "Notification Title",
                    hint: "e.g. Dinner is Served",
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _bodyCtrl,
                    label: "Message Body",
                    hint: "Enter your message here...",
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          _buildSendButton(),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Colors.black45,
    letterSpacing: 1,
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (val) {
          // Deselect template if user starts typing manually
          if (_selectedTemplateIndex != null)
            setState(() => _selectedTemplateIndex = null);
        },
        style: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontFamily: fontFamily,
            color: accentGold,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardBg,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _sending ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDeep,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _sending
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  "Send Notification",
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final _NotiTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B1139) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B1139)
                : const Color(0xFF6B1139).withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Text(
          template.label,
          style: TextStyle(
            fontFamily: _AdminNotificationsScreenState.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF6B1139),
          ),
        ),
      ),
    );
  }
}

class _EventDropdown extends StatelessWidget {
  final String weddingId;
  final String? value;
  final void Function(String?) onChanged;

  const _EventDropdown({
    required this.weddingId,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final eventsRef = FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('events');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: eventsRef.orderBy('dateTime').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text(
                "Choose Target Event",
                style: TextStyle(
                  fontFamily: _AdminNotificationsScreenState.fontFamily,
                  fontSize: 14,
                  color: Colors.black38,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFB0773B),
              ),
              items: docs.map((d) {
                final data = d.data();
                final title = (data['title'] ?? data['name'] ?? 'Event')
                    .toString();
                return DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: _AdminNotificationsScreenState.fontFamily,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2A27),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

class _NotiTemplate {
  final String label;
  final String title;
  final String body;
  const _NotiTemplate({
    required this.label,
    required this.title,
    required this.body,
  });
}
