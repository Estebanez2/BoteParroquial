import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../repositories/push_device_repository.dart';
import '../../../services/file_push_registration_service.dart';
import '../../../services/file_push_consent_service.dart';
import '../../../services/firebase_push_messaging_service.dart';
import '../../../services/firestore_notification_service.dart';

final pushDeviceRepositoryProvider = Provider<PushDeviceRepository>(
  (ref) => PushDeviceRepository(
    FirebasePushMessagingService(ref.watch(firebaseAuthProvider)),
    FirestoreNotificationService(ref.watch(firestoreProvider)),
    FilePushRegistrationService(),
    consent: FilePushConsentService(),
  ),
);
