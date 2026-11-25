import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/home_page.dart';
import 'services/desktop_notifier.dart';
import 'services/relay_sync.dart';
import 'services/storage.dart';
import 'state/timer_model.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(1180, 740), minimumSize: Size(960, 620), title: 'Focus Desk', titleBarStyle: TitleBarStyle.hidden),
    () async {
      await windowManager.show();
    },
  );
  final storage = await Storage.open();
  final model = TimerModel(storage: storage, sync: RelaySync(baseUrl: storage.loadSettings().relayUrl), notifier: await DesktopNotifier.create())..init();
  runApp(ChangeNotifierProvider.value(value: model, child: const FocusApp()));
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Focus Desk', debugShowCheckedModeBanner: false, theme: buildTheme(), home: const HomePage());
}
