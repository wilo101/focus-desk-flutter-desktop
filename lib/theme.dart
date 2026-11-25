import 'package:flutter/material.dart';

const ink = Color(0xFF14130F);
const forest = Color(0xFF2F6B4F);
const muted = Color(0xFF7A7568);
const paper = Color(0xFFF6F8F1);
const hairline = Color(0x2214130F);
const serif = TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['Gentium Plus', 'serif']);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(primary: ink, secondary: forest, surface: paper, onSurface: ink),
      scaffoldBackgroundColor: paper,
      dividerColor: hairline,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: ink)),
        isDense: true,
      ),
    );
