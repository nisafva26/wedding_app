import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:wedding_invite/feature/guest_list/controllers/guest_provider.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';


import '../../../utils/phone_utils.dart';

class ContactPickerSheet extends StatefulWidget {
  final List<WeddingGuest> existingGuests;

  const ContactPickerSheet({
    super.key,
    required this.existingGuests,
  });

  @override
  State<ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<ContactPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  bool _permissionDenied = false;

  List<Contact> _allContacts = [];
  final Set<String> _selectedContactIds = {};
  bool _initializedFromGuests = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    contacts.sort((a, b) => a.displayName.compareTo(b.displayName));

    setState(() {
      _allContacts = contacts;
      _loading = false;
    });

    _initSelectionFromGuests();
  }

  void _initSelectionFromGuests() {
    if (_initializedFromGuests || _allContacts.isEmpty) return;
    _initializedFromGuests = true;

    final guestPhones = <String>{};
    final guestContactIds = <String>{};

    for (final g in widget.existingGuests) {
      if (g.sourceContactId != null) guestContactIds.add(g.sourceContactId!);
      guestPhones.add(normalizePhone(g.phone));
    }

    for (final c in _allContacts) {
      final hasIdMatch =
          guestContactIds.contains(c.id);

      final phone =
          c.phones.isNotEmpty ? normalizePhone(c.phones.first.number) : '';
      final hasPhoneMatch =
          phone.isNotEmpty && guestPhones.contains(phone);

      if (hasIdMatch || hasPhoneMatch) {
        _selectedContactIds.add(c.id);
      }
    }

    setState(() {});
  }

  List<Contact> get _filteredContacts {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allContacts;
    return _allContacts.where((c) {
      final name = c.displayName.toLowerCase();
      final phone = c.phones.isNotEmpty
          ? c.phones.first.number.toLowerCase()
          : '';
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  void _toggleSelection(Contact c) {
    setState(() {
      if (_selectedContactIds.contains(c.id)) {
        _selectedContactIds.remove(c.id);
      } else {
        _selectedContactIds.add(c.id);
      }
    });
  }

  void _confirmSelection() {
    final selected = _allContacts
        .where((c) => _selectedContactIds.contains(c.id))
        .toList();

    final inputs = selected.map((c) {
      final name = c.displayName.trim();
      final rawPhone =
          c.phones.isNotEmpty ? c.phones.first.number.trim() : '';
      final phone = normalizePhone(rawPhone);
      final email =
          c.emails.isNotEmpty ? c.emails.first.address.trim() : null;

      return GuestInput(
        name: name,
        phone: phone,
        email: email,
        sourceContactId: c.id,
      );
    }).where((g) => g.phone.isNotEmpty).toList();

    Navigator.of(context).pop(inputs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Add from contacts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.secondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedContactIds.length} selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchField(controller: _searchCtrl),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBody(theme, colors),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _selectedContactIds.isEmpty
                            ? null
                            : _confirmSelection,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: Text(
                          _selectedContactIds.isEmpty
                              ? 'Add guests'
                              : 'Add ${_selectedContactIds.length} guests',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colors) {
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Contacts permission denied. Please enable Contacts access in Settings to choose guests.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.secondary.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allContacts.isEmpty) {
      return const Center(child: Text('No contacts found on this device'));
    }

    final filtered = _filteredContacts;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final c = filtered[index];
        final isSelected = _selectedContactIds.contains(c.id);
        final phone = c.phones.isNotEmpty
            ? normalizePhone(c.phones.first.number)
            : '';

        final email =
            c.emails.isNotEmpty ? c.emails.first.address.trim() : null;

        return _ContactTile(
          name: c.displayName,
          phone: phone,
          email: email,
          isSelected: isSelected,
          onTap: () => _toggleSelection(c),
        );
      },
    );
  }
}

// ---------- Contact sheet widgets ----------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search contacts',
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.secondary.withOpacity(0.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3D3C5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE3D3C5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String name;
  final String phone;
  final String? email;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactTile({
    required this.name,
    required this.phone,
    required this.email,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final initials = _initialsFromName(name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.primary.withOpacity(0.8)
                : const Color(0xFFE3D3C5),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withOpacity(0.4),
                    colors.primary.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.secondary,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                  if (email != null && email!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary.withOpacity(0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? colors.primary
                      : const Color(0xFFD9C8BA),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}
