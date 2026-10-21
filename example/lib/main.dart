import 'package:flutter/material.dart';

import 'theme/tokens.dart';

void main() => runApp(const ExampleApp());

/// The example app.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: Scaffold(body: Body()));
}

/// Deliberately mixes reported and accepted sizing, so that running
/// `dart analyze` in this directory shows what the plugin does.
class Body extends StatelessWidget {
  /// Creates the body.
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // REPORTED: raw_edge_insets
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // REPORTED: raw_box_dimension
          const SizedBox(height: 32),

          // ACCEPTED: a design token, not a literal.
          const SizedBox(height: AppSpacing.md),

          // ACCEPTED: 0 and 1 are never reported.
          const SizedBox(height: 1),

          Text(
            'Reported font size',
            // REPORTED: raw_font_size
            style: const TextStyle(fontSize: 18),
          ),

          Text(
            'Accepted font size',
            style: const TextStyle(
              // ACCEPTED: a design token.
              fontSize: AppText.body,
              // ACCEPTED: `height` on TextStyle is a line-height multiplier,
              // not a pixel measurement, so it is never reported.
              height: 1.4,
            ),
          ),

          // ACCEPTED: suppressed for this one line.
          // ignore: dimension_lint/raw_box_dimension
          const SizedBox(height: 40),

          const Divider(
            // ACCEPTED: a hairline, which must not scale.
            thickness: 1.5,
          ),
        ],
      ),
    );
  }
}
