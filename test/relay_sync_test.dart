import 'package:flutter_test/flutter_test.dart';
import 'package:focus_desk/services/relay_sync.dart';
import 'helpers.dart';

void main() {
  test('push posts task, minutes and tag', () async {
    final r = FakeRelay();
    final s = RelaySync(client: r.client);
    expect(await s.push(sess(DateTime(2026), minutes: 30, tag: 'work', task: 'x')), true);
    expect(r.posted.single, {'task': 'x', 'minutes': 30, 'tag': 'work'});
    expect(s.reachable, true);
  });

  test('push returns false when offline', () async {
    final r = FakeRelay()..online = false;
    final s = RelaySync(client: r.client);
    expect(await s.push(sess(DateTime(2026))), false);
    expect(s.reachable, false);
  });

  test('flush marks sent sessions and skips synced ones', () async {
    final r = FakeRelay();
    final s = RelaySync(client: r.client);
    final out = await s.flush([sess(DateTime(2026)).markSynced(), sess(DateTime(2026)), sess(DateTime(2026))]);
    expect(out.every((e) => e.synced), true);
    expect(r.posted.length, 2);
  });

  test('flush leaves everything unsynced when offline', () async {
    final r = FakeRelay()..online = false;
    final out = await RelaySync(client: r.client).flush([sess(DateTime(2026)), sess(DateTime(2026))]);
    expect(out.where((e) => e.synced), isEmpty);
  });
}
