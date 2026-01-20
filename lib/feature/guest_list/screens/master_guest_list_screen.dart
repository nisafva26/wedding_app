import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wedding_invite/feature/guest_list/screens/master_guest_list_loaded.dart';

import '../../wedding_admin/provider/wedding_provider.dart'; // currentWeddingStreamProvider



class MasterGuestListScreen extends ConsumerWidget {
  const MasterGuestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weddingAsync = ref.watch(currentWeddingStreamProvider);

    return weddingAsync.when(
      data: (wedding) {
        if (wedding == null) {
          return const Scaffold(
            body: Center(child: Text('No wedding project found')),
          );
        }

        return MasterGuestListLoaded(
          weddingId: wedding.id,
          weddingName: wedding.name,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}


