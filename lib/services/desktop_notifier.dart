import 'package:local_notifier/local_notifier.dart';
import 'notifier.dart';

class DesktopNotifier implements Notifier {
  static Future<DesktopNotifier> create() async {
    await localNotifier.setup(appName: 'Focus Desk');
    return DesktopNotifier();
  }

  @override
  Future<void> show(String title, String body) => LocalNotification(title: title, body: body).show();
}
