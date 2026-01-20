import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/event_model.dart';
import 'package:wedding_invite/feature/wedding_admin/domain/wedding_model.dart';
import 'package:wedding_invite/feature/wedding_admin/provider/event_provider.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  final String weddingId;

  const AddEventScreen({super.key, required this.weddingId});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _themeCtrl = TextEditingController();

  DateTime? _selectedDateTime;
  EventType? _selectedType;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _themeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: const Color(0xFFFFF2E9),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: const Color(0xFFFFF2E9),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveEvent(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an event type and date & time.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final event = Event(
        id: '', // Firestore will generate
        weddingId: widget.weddingId,
        name: _nameCtrl.text.trim(),
        type: _selectedType!,
        dateTime: _selectedDateTime!,
        venue: _venueCtrl.text.trim(),
        theme: _themeCtrl.text.trim(),
      );

      await ref.read(eventsControllerProvider).addEvent(event);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    const backgroundColor = Color(0xFFFFF8F3);
    final dateLabel = _selectedDateTime == null
        ? 'Pick date & time'
        : DateFormat('EEE, dd MMM yyyy • h:mm a')
            .format(_selectedDateTime!);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Add event',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.secondary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
              color: colors.secondary.withOpacity(0.9)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Small subheading under app bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Set up each ceremony with a clear name, time and venue. You can always edit later.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.secondary.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),

                // Section 1: Basics
                _SectionCard(
                  title: 'Event basics',
                  subtitle: 'Give this ceremony a clear identity.',
                  icon: Icons.auto_awesome_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Event name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration:
                            _inputDecoration(context, 'e.g. Nisaf’s Haldi'),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter an event name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel('Event type'),
                      const SizedBox(height: 8),
                      _EventTypeChips(
                        selected: _selectedType,
                        onChanged: (type) {
                          setState(() => _selectedType = type);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Section 2: When & where
                _SectionCard(
                  title: 'When & where',
                  subtitle: 'Lock in the timing and location.',
                  icon: Icons.event_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Date & time'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _pickDateTime(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedDateTime == null
                                  ? const Color(0xFFE3D3C5)
                                  : colors.primary.withOpacity(0.9),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primary.withOpacity(0.08),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dateLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _selectedDateTime == null
                                        ? colors.secondary.withOpacity(0.55)
                                        : colors.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.secondary.withOpacity(0.45),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel('Venue'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _venueCtrl,
                        decoration: _inputDecoration(
                          context,
                          'e.g. Grand Hyatt, Kochi',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a venue';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Section 3: Theme
                _SectionCard(
                  title: 'Style & theme',
                  subtitle: 'Optional dress code or visual vibe.',
                  icon: Icons.palette_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Theme (optional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _themeCtrl,
                        decoration: _inputDecoration(
                          context,
                          'e.g. Yellow dress • Marigold decor',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    onPressed: _isSaving ? null : () => _saveEvent(context),
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3D3C5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE3D3C5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.primary,
          width: 1.6,
        ),
      ),
    );
  }
}

// ---------- SUB WIDGETS ----------

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const borderColor = Color(0xFFE4D6C7);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withOpacity(0.10),
                ),
                child: Icon(icon, size: 16, color: colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.secondary.withOpacity(0.9),
      ),
    );
  }
}

class _EventTypeChips extends StatelessWidget {
  final EventType? selected;
  final ValueChanged<EventType> onChanged;

  const _EventTypeChips({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final options = <EventType, String>{
      EventType.haldi: 'Haldi',
      EventType.mehendi: 'Mehendi',
      EventType.wedding: 'Wedding',
      EventType.reception: 'Reception',
      EventType.other: 'Other',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final isSelected = selected == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: isSelected,
          onSelected: (_) => onChanged(e.key),
          selectedColor: colors.primary.withOpacity(0.15),
          labelStyle: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? colors.primary
                : colors.secondary.withOpacity(0.9),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? colors.primary.withOpacity(0.8)
                  : const Color(0xFFE3D3C5),
            ),
          ),
          backgroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
