import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendTestPush() async {
  final callable =
      FirebaseFunctions.instance.httpsCallable('debugSendEventNotification');

  final res = await callable.call({
    'weddingId': 'u7MmJS2IEIjOGax9E6md',
    'eventId': 'dd2U0RP8Av865HSpXCMR',
  });

  print('Push result: ${res.data}');
}
