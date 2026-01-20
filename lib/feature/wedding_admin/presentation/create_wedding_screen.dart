import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; 
// Import your Wedding model

// Define a provider to hold the form state (optional, but good practice)
// For simplicity here, we'll use a State/Stateful widget.

class CreateWeddingScreen extends StatefulWidget {
  const CreateWeddingScreen({super.key});

  @override
  State<CreateWeddingScreen> createState() => _CreateWeddingScreenState();
}

class _CreateWeddingScreenState extends State<CreateWeddingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();

  DateTime? _dateStart;
  DateTime? _dateEnd;
  bool _isLoading = false;

  // --- Date Picker Helper ---
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years out
      currentDate: DateTime.now(),
      initialDateRange: _dateStart != null && _dateEnd != null
          ? DateTimeRange(start: _dateStart!, end: _dateEnd!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            // Use your primary color for selection
            primaryColor: Theme.of(context).colorScheme.primary, 
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, 
            ),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateStart = picked.start;
        _dateEnd = picked.end;
      });
    }
  }
  // --- END Date Picker Helper ---

  // --- Firestore Save Logic ---
  Future<void> _createWeddingProject(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateStart == null || _dateEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      setState(() => _isLoading = false);
      context.go('/'); // Redirect to login
      return;
    }

    try {
      final weddingData = {
        'name': _nameController.text.trim(),
        'dateStart': Timestamp.fromDate(_dateStart!),
        'dateEnd': Timestamp.fromDate(_dateEnd!),
        'venue': _venueController.text.trim(),
        'admins': [user.uid], // Using the 'admins' array as per the plan
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('weddings').add(weddingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Wedding Project Created!')),
        );
        // Navigate back to the Home screen, which will now show the dashboard
        context.go('/home'); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- END Firestore Save Logic ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Wedding Project'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Match background
        elevation: 0,
        // leading: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💎 Premium Header
                const Text(
                  'Set the Stage for Your Big Day',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5C3C3C), // Accent Color
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Let\'s gather the essential details to kick off your planning.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // 1. Wedding Name
                _buildInputLabel('Wedding Name (e.g., "Sarah & Alex")'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a memorable name',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // 2. Date Range Picker (Premium UX)
                _buildInputLabel('Wedding Date Range'),
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _dateStart == null ? const Color(0xFFE3D3C5) : Theme.of(context).colorScheme.primary,
                        width: _dateStart == null ? 1 : 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dateStart == null
                                ? 'Select Start Date to End Date'
                                : '${DateFormat.yMMMd().format(_dateStart!)} - ${DateFormat.yMMMd().format(_dateEnd!)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _dateStart == null ? const Color(0xFFB08C82).withOpacity(0.6) : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Venue
                _buildInputLabel('Main Wedding Venue'),
                TextFormField(
                  controller: _venueController,
                  decoration: const InputDecoration(
                    hintText: 'Enter the location (e.g., Grand Ballroom)',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 40),

                // 4. Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : () => _createWeddingProject(context),
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isLoading ? 'Creating Project...' : 'Create Project'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for label style
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF8A6A60), // Earthy brown/grey
        ),
      ),
    );
  }
}