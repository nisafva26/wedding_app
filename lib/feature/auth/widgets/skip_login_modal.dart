// lib/widgets/auth/skip_login_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wedding_invite/router/router_provider.dart';


void showGuestGateSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Skip Login?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text('You can view the main wedding dashboard, but you won\'t be able to save events or manage guests without logging in.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(isGuestProvider.notifier).state = true;
                  context.go('/home');
                },
                child: const Text('Continue as Guest'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go back to Login'),
            ),
          ],
        ),
      );
    },
  );
}