import '../widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 80,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 20),
          AppText(
            context.l.underDevelopment,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          AppText(
            context.l.featureNotAvailable,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

