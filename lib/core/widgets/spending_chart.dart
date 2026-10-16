import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../theme/kwall_theme.dart';

class SpendingChartWidget extends StatelessWidget {
  final List<DailySpend> dailySpends;
  final List<CategoryBreakdown> categoryBreakdowns;
  final String currency;

  const SpendingChartWidget({
    super.key,
    required this.dailySpends,
    required this.categoryBreakdowns,
    this.currency = '\$',
  });

  @override
  Widget build(BuildContext context) {
    if (dailySpends.isEmpty) return const SizedBox.shrink();

    final maxSpend = dailySpends.fold<double>(0.0, (max, d) => d.amount > max ? d.amount : max);
    final validMax = maxSpend <= 0 ? 50.0 : maxSpend;
    final totalWeek = dailySpends.fold<double>(0.0, (sum, d) => sum + d.amount);
    final dailyAvg = totalWeek / dailySpends.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KwallTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KwallTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastos últimos 7 días',
                    style: KwallTheme.fontTitle.copyWith(
                      fontSize: 15,
                      color: KwallTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Promedio diario: ${KwallTheme.formatCurrency(dailyAvg, currency)}',
                    style: KwallTheme.fontBody.copyWith(
                      fontSize: 12,
                      color: KwallTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: KwallTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${KwallTheme.formatCurrency(totalWeek, currency)} total',
                  style: KwallTheme.fontTitle.copyWith(
                    color: KwallTheme.accent,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Expressive 7-Day Bar Chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailySpends.map((day) {
                final ratio = (day.amount / validMax).clamp(0.04, 1.0);
                final isToday = day.dayLabel == 'Hoy';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.amount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              day.amount >= 100
                                  ? '${day.amount.toInt()}'
                                  : day.amount.toStringAsFixed(0),
                              style: KwallTheme.fontBody.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isToday ? KwallTheme.accent : KwallTheme.textMuted,
                              ),
                            ),
                          ),
                        // Pill Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: (120 - 45) * ratio,
                          decoration: BoxDecoration(
                            color: isToday
                                ? KwallTheme.accent
                                : (day.amount > 0
                                    ? KwallTheme.surfaceElevated
                                    : KwallTheme.surfaceContainer),
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: KwallTheme.accentLight, width: 1.0)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          day.dayLabel,
                          style: KwallTheme.fontBody.copyWith(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? KwallTheme.accent : KwallTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Category distribution breakdown if any
          if (categoryBreakdowns.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(color: KwallTheme.border, height: 1),
            const SizedBox(height: 14),
            Text(
              'Distribución del mes',
              style: KwallTheme.fontTitle.copyWith(
                fontSize: 13,
                color: KwallTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: categoryBreakdowns.take(4).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.category.iconData,
                                size: 14,
                                color: Color(item.category.colorValue),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.category.name,
                                style: KwallTheme.fontBody.copyWith(
                                  fontSize: 12,
                                  color: KwallTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.percentage.toStringAsFixed(0)}% • ${KwallTheme.formatCurrency(item.amount, currency)}',
                            style: KwallTheme.fontBody.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: KwallTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.percentage / 100,
                          minHeight: 6,
                          backgroundColor: KwallTheme.surfaceContainer,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(item.category.colorValue),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
