import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'home_page.dart';
import 'timer_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(1180, 740), minimumSize: Size(900, 600), title: 'Focus Desk', titleBarStyle: TitleBarStyle.hidden),
    () async {
      await windowManager.show();
    },
  );
  runApp(ChangeNotifierProvider(create: (_) => TimerModel()..init(), child: const FocusApp()));
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Focus Desk',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF14130F),
            secondary: Color(0xFF2F6B4F),
            surface: Color(0xFFF6F8F1),
            onSurface: Color(0xFF14130F),
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F8F1),
        ),
        home: const HomePage(),
      );
}
