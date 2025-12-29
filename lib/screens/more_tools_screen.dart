import 'package:flutter/material.dart';
import '../widgets/app_text.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import 'names_of_allah_screen.dart';
import 'qibla_finder_screen.dart';
import 'prayer_times_screen.dart';

class MoreToolsScreen extends StatelessWidget {
  const MoreToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRTL = context.isRTL;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tools = _getTools(context);

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      child: CustomScrollView(
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  AppText(
                    context.l.islamicTools,
                    style: context.textStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    context.l.otherTools,
                    style: context.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tools grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _ToolCard(
                    tool: tools[index],
                    isRTL: isRTL,
                    isDark: isDark,
                  );
                },
                childCount: tools.length,
              ),
            ),
          ),

          // Bottom padding for navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  List<ToolItem> _getTools(BuildContext context) {
    return [
      ToolItem(
        icon: Icons.explore_rounded,
        title: context.l.qiblaFinder,
        description: context.l.qiblaFinderDesc,
        color: const Color(0xFF2196F3),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const QiblaFinderScreen(),
            ),
          );
        },
      ),
      ToolItem(
        icon: Icons.access_time_rounded,
        title: context.l.prayerTimes,
        description: context.l.prayerTimesDesc,
        color: const Color(0xFF4CAF50),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PrayerTimesScreen(),
            ),
          );
        },
      ),
      ToolItem(
        icon: Icons.circle_outlined,
        title: context.l.tasbeehCounter,
        description: context.l.tasbeehCounterDesc,
        color: const Color(0xFF9C27B0),
        onTap: () {
          // TODO: Navigate to Tasbeeh Counter
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppText(context.l.comingSoon)),
          );
        },
      ),
      ToolItem(
        icon: Icons.calendar_today_rounded,
        title: context.l.hijriCalendar,
        description: context.l.hijriCalendarDesc,
        color: const Color(0xFFFF9800),
        onTap: () {
          // TODO: Navigate to Hijri Calendar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppText(context.l.comingSoon)),
          );
        },
      ),
      ToolItem(
        icon: Icons.mosque_rounded,
        title: context.l.namesOfAllah,
        description: context.l.namesOfAllahDesc,
        color: const Color(0xFF006653),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NamesOfAllahScreen(),
            ),
          );
        },
      ),
      ToolItem(
        icon: Icons.format_quote_rounded,
        title: context.l.islamicQuotes,
        description: context.l.islamicQuotesDesc,
        color: const Color(0xFFE91E63),
        onTap: () {
          // TODO: Navigate to Islamic Quotes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppText(context.l.comingSoon)),
          );
        },
      ),
      ToolItem(
        icon: Icons.auto_awesome_rounded,
        title: context.l.duaCollection,
        description: context.l.duaCollectionDesc,
        color: const Color(0xFF00BCD4),
        onTap: () {
          // TODO: Navigate to Dua Collection
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppText(context.l.comingSoon)),
          );
        },
      ),
      ToolItem(
        icon: Icons.account_balance_wallet_rounded,
        title: context.l.zakat,
        description: context.l.zakatDesc,
        color: const Color(0xFFFF5722),
        onTap: () {
          // TODO: Navigate to Zakat Calculator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: AppText(context.l.comingSoon)),
          );
        },
      ),
    ];
  }
}

class _ToolCard extends StatelessWidget {
  final ToolItem tool;
  final bool isRTL;
  final bool isDark;

  const _ToolCard({
    required this.tool,
    required this.isRTL,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark 
        ? const Color(0xFF2D2D2D) 
        : Colors.white;
    final borderColor = isDark 
        ? tool.color.withOpacity(0.2) 
        : tool.color.withOpacity(0.12);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : tool.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: tool.onTap,
          splashColor: tool.color.withOpacity(0.15),
          highlightColor: tool.color.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Icon with background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tool.color.withOpacity(0.15),
                        tool.color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: tool.color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    tool.icon,
                    color: tool.color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            tool.title,
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            style: context.textStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            tool.description,
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            style: context.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Decorative accent line
                      Container(
                        width: 28,
                        height: 3,
                        decoration: BoxDecoration(
                          color: tool.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToolItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const ToolItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });
}

