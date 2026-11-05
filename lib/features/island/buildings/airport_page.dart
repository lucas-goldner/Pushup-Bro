import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

/// What the building offers once it's built. A placeholder for now.
class AirportPage extends StatelessWidget {
  const AirportPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.buildingAirport)),
      );
}
