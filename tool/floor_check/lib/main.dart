// One case per rule, and nothing else. This file is analyzed by the oldest
// supported Dart SDK, so it must avoid anything newer: in particular the dot
// shorthand the main example uses, which resolves through redirecting factories
// on `EdgeInsetsGeometry` that Flutter 3.41 does not declare.
import 'package:flutter/material.dart';

/// Builds the widget whose literals the three rules are expected to report.
Widget build() => const Padding(
  padding: EdgeInsets.all(24),
  child: Column(
    children: [
      SizedBox(height: 32),
      Text('reported', style: TextStyle(fontSize: 18)),
    ],
  ),
);
