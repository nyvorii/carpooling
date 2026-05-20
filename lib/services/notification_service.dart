import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// wyslanie powiadomienie w aplikacji do konkretnego użytkownika
  Future<void> sendInAppNotification({
    required String userId,
    required String routeId,
    required String title,
    required String body,
    Map<String, dynamic>? changes,
  }) async {
    final notification = NotificationModel(
      id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      routeId: routeId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      changes: changes,
    );

    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toFirestore());
  }

  /// powiadomienie wszystkich pasażerów z potwierdzoną rezerwacją o zmianach w trasie
  Future<void> notifyPassengersAboutRouteChange(
      String routeId,
      Map<String, dynamic> changes,
      ) async {
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('routeId', isEqualTo: routeId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    if (bookingsSnapshot.docs.isEmpty) return;

    final changeDescriptions = <String>[];
    if (changes.containsKey('date')) changeDescriptions.add('godziny odjazdu');
    if (changes.containsKey('startAddress') || changes.containsKey('endAddress')) {
      changeDescriptions.add('miejsca startu/końca');
    }
    if (changes.containsKey('seats')) changeDescriptions.add('liczby dostępnych miejsc');
    if (changes.containsKey('totalCost')) changeDescriptions.add('kosztu przejazdu');

    final changesText = changeDescriptions.join(', ');
    final title = 'Zmiana w trasie';
    final body = 'Kierowca zmienił: $changesText. Sprawdź szczegóły w aplikacji.';

    for (final bookingDoc in bookingsSnapshot.docs) {
      final passengerId = bookingDoc['passengerId'] as String;
      await sendInAppNotification(
        userId: passengerId,
        routeId: routeId,
        title: title,
        body: body,
        changes: changes,
      );
    }
  }

  /// stream powiadomień dla danego użytkownika (od najnowszych)
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList());
  }

  /// oznacza pojedyncze powiadomienie jako przeczytane
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// oznacza wszystkie powiadomienia użytkownika jako przeczytane
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}