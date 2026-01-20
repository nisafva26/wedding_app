import 'package:flutter/material.dart';
import 'package:wedding_invite/feature/guest_list/models/wedding_guest.dart';
import 'package:wedding_invite/feature/wedding_admin/event_details/providers/event_guest_provider.dart';
import 'package:wedding_invite/utils/phone_utils.dart';


class ManageEventGuestsSheet extends StatefulWidget {
  final String eventName;
  final List<WeddingGuest> masterGuests;
  final List<EventGuest> existingEventGuests;

  const ManageEventGuestsSheet({
    super.key,
    required this.eventName,
    required this.masterGuests,
    required this.existingEventGuests,
  });

  @override
  State<ManageEventGuestsSheet> createState() =>
      _ManageEventGuestsSheetState();
}

class _ManageEventGuestsSheetState
    extends State<ManageEventGuestsSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedGuestIds = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));

    // pre-select guests already added to this event
    for (final g in widget.existingEventGuests) {
      _selectedGuestIds.add(g.id); // event guest doc id == master guest id
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WeddingGuest> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return widget.masterGuests;
    return widget.masterGuests.where((g) {
      final name = g.name.toLowerCase();
      final phone = normalizePhone(g.phone).toLowerCase();
      final email = (g.email ?? '').toLowerCase();
      return name.contains(q) ||
          phone.contains(q) ||
          email.contains(q);
    }).toList();
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedGuestIds.contains(id)) {
        _selectedGuestIds.remove(id);
      } else {
        _selectedGuestIds.add(id);
      }
    });
  }

  void _confirm() {
    final selected = widget.masterGuests
        .where((g) => _selectedGuestIds.contains(g.id))
        .toList();

    final inputs = selected
        .map(
          (g) => EventGuestInput(
            guestId: g.id,
            name: g.name,
            phone: g.phone,
            email: g.email,
          ),
        )
        .toList();

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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guests for ${widget.eventName}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pick from your master list',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: colors.secondary
                                    .withOpacity(0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(999),
                          color:
                              colors.primary.withOpacity(0.08),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_selectedGuestIds.length}',
                              style: theme
                                  .textTheme.labelMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colors.secondary.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3D3C5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3D3C5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final g = _filtered[index];
                      final isSelected =
                          _selectedGuestIds.contains(g.id);
                      final phone =
                          normalizePhone(g.phone);

                      return _MasterGuestTile(
                        name: g.name,
                        phone: phone,
                        email: g.email,
                        isSelected: isSelected,
                        onTap: () => _toggle(g.id),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _selectedGuestIds.isEmpty
                            ? null
                            : _confirm,
                        child: Text(
                          _selectedGuestIds.isEmpty
                              ? 'Save guests'
                              : 'Save ${_selectedGuestIds.length} guests',
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
}

class _MasterGuestTile extends StatelessWidget {
  final String name;
  final String phone;
  final String? email;
  final bool isSelected;
  final VoidCallback onTap;

  const _MasterGuestTile({
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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? colors.primary.withOpacity(0.9)
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withOpacity(0.7),
                    colors.primary.withOpacity(0.35),
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
                  if (email != null && email!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colors.secondary.withOpacity(0.55),
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
                color:
                    isSelected ? colors.primary : Colors.white,
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
