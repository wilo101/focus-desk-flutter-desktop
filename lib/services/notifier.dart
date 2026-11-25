/// Desktop notification when a block ends. The app only talks to this interface.
abstract class Notifier {
  Future<void> show(String title, String body);
}

class SilentNotifier implements Notifier {
  @override
  Future<void> show(String title, String body) async {}
}

/// Records what would have been shown. Used in tests.
class FakeNotifier implements Notifier {
  final List<(String, String)> shown = [];
  @override
  Future<void> show(String title, String body) async => shown.add((title, body));
}
