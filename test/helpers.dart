import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_desk/models/models.dart';
import 'package:focus_desk/services/notifier.dart';
import 'package:focus_desk/services/relay_sync.dart';
import 'package:focus_desk/services/storage.dart';
import 'package:focus_desk/state/timer_model.dart';

Session sess(DateTime at, {int minutes = 25, String tag = '', String task = 't'}) => Session(task: task, minutes: minutes, at: at, tag: tag);

/// A fake Relay. [online] false makes every request fail, like no network.
class FakeRelay {
  bool online = true;
  final posted = <Map<String, dynamic>>[];
  late final http.Client client = MockClient((req) async {
    if (!online) throw http.ClientException('offline');
    if (req.url.path == '/auth/login') return http.Response(jsonEncode({'token': 'tok', 'role': 'admin'}), 200);
    if (req.url.path == '/focus/sessions' && req.method == 'POST') {
      posted.add(jsonDecode(req.body) as Map<String, dynamic>);
      return http.Response('{}', 201);
    }
    return http.Response('{}', 404);
  });
}

Future<(TimerModel, FakeRelay, FakeNotifier)> makeModel({DateTime Function()? clock, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await Storage.open();
  final relay = FakeRelay();
  final n = FakeNotifier();
  final m = TimerModel(storage: storage, sync: RelaySync(client: relay.client), notifier: n, clock: clock);
  return (m, relay, n);
}

void runBlock(TimerModel m) {
  m.start();
  while (m.running && m.remaining > 0) {
    m.tick();
  }
}
