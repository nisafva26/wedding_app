import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRole;
  bool _isSaving = false;

  final _roles = const [
    'Bride',
    'Groom',
    'Guest',
    'Bridesmaid',
    'Groomsman',
    'Family',
    'Friend',
    'Vendor / Crew',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDetails() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role in the wedding.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged in user found.')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'role': _selectedRole,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'photoUrl': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // TODO: change "/home" to your actual main screen route
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFDF7F2), // soft warm
                Color(0xFFF3E5DB),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDBC7B2).withOpacity(0.35),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildContentCard(t, size),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(TextTheme t, Size size) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.88),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE6D3C3),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge / step indicator
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F1E0F).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFB47A41)),
                    const SizedBox(width: 6),
                    Text(
                      'Let’s personalise your space',
                      style: t.labelMedium?.copyWith(
                        letterSpacing: 0.2,
                        color: const Color(0xFF7C5B3B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome to your\nwedding hub ✨',
              style: t.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF25160E),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us who you are so we can tailor the events, tasks,\nand invites just for you.',
              style: t.bodyMedium?.copyWith(
                color: const Color(0xFF8A6C52),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Name field
            Text(
              'Your name',
              style: t.labelLarge?.copyWith(
                color: const Color(0xFF4C3420),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'e.g., Hanna Mathew',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: const Color(0xFFF8F1EB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE3CBB5),
                    width: 1.3,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE3CBB5),
                    width: 1.3,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFB47A41),
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name looks too short';
                }
                return null;
              },
            ),

            const SizedBox(height: 22),

            // Role title
            Text(
              'Your role in this wedding',
              style: t.labelLarge?.copyWith(
                color: const Color(0xFF4C3420),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            _buildRoleGrid(t),

            const SizedBox(height: 24),

            // Continue button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUserDetails,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFB47A41),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB47A41).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.center,
              child: Text(
                'You can edit these later in Profile',
                style: t.bodySmall?.copyWith(
                  color: const Color(0xFFAA8C70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleGrid(TextTheme t) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _roles.map((role) {
        final isSelected = _selectedRole == role;
        return _RoleCard(
          label: role,
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedRole = role;
            });
          },
        );
      }).toList(),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (label) {
      case 'Bride':
        return Icons.favorite_rounded;
      case 'Groom':
        return Icons.male_rounded;
      case 'Guest':
        return Icons.confirmation_num_outlined;
      case 'Bridesmaid':
        return Icons.spa_rounded;
      case 'Groomsman':
        return Icons.time_to_leave; // if not available, Flutter will replace, you can change
      case 'Family':
        return Icons.family_restroom_rounded;
      case 'Friend':
        return Icons.group_rounded;
      case 'Vendor / Crew':
        return Icons.work_outline_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final bg = selected
        ? const LinearGradient(
            colors: [
              Color(0xFFB47A41),
              Color(0xFFD9A662),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFF8F1EB),
              Color(0xFFF2E4D9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor =
        selected ? const Color(0xFFB47A41) : const Color(0xFFE5D4C3);

    final textColor = selected
        ? Colors.white
        : const Color(0xFF5D4128);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB47A41).withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF9B7650),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
