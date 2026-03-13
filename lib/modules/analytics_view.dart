import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _pageBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F1220) : const Color(0xFFF4F7FF);

  Color _surface(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1E33) : Colors.white;

  Color _surfaceAlt(BuildContext context) =>
      _isDark(context) ? const Color(0xFF15192C) : const Color(0xFFF9FAFF);

  Color _textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  Color _textMuted(BuildContext context) =>
      _isDark(context) ? Colors.white70 : Colors.black54;

  Color _border(BuildContext context) =>
      _isDark(context)
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _pageBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(
                alpha: _isDark(context) ? 0.2 : 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: scheme.primary,
            ),
          ),
          onPressed: Get.back,
        ),
        title: Text(
          'Analytics',
          style: TextStyle(
            color: _textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
              backgroundColor: scheme.primary.withValues(
                alpha: _isDark(context) ? 0.2 : 0.1,
              ),
              label: Text(
                'This Week',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: scheme.primary),
          );
        }

        final data = controller.analyticsData;
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No analytics data available',
              style: TextStyle(color: _textMuted(context)),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _buildHeader(context, data),
            const SizedBox(height: 16),
            _buildKpiRow(context, data),
            const SizedBox(height: 16),
            _buildCompletionRing(context, data),
            const SizedBox(height: 16),
            _buildWeeklyChart(context, data['completionByDay']),
            const SizedBox(height: 16),
            _buildCategoryDonut(context, data['tasksByCategory']),
            const SizedBox(height: 16),
            _buildPriorityBreakdown(context, data),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surface(context), _surfaceAlt(context)],
        ),
        border: Border.all(color: _border(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            '${data['totalTasks'] ?? 0} tasks tracked',
            style: TextStyle(
              color: _textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, Map<String, dynamic> data) {
    final cards = [
      (
        label: 'Total',
        value: data['totalTasks'] ?? 0,
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.list_alt_rounded,
      ),
      (
        label: 'Done',
        value: data['completed'] ?? 0,
        color: const Color(0xFF12B886),
        icon: Icons.check_circle_outline_rounded,
      ),
      (
        label: 'Pending',
        value: data['pending'] ?? 0,
        color: const Color(0xFFF59F00),
        icon: Icons.hourglass_top_rounded,
      ),
      (
        label: 'Overdue',
        value: data['overdue'] ?? 0,
        color: const Color(0xFFE03131),
        icon: Icons.warning_amber_rounded,
      ),
    ];

    return Row(
      children: List.generate(cards.length, (index) {
        final item = cards[index];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < cards.length - 1 ? 10 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withValues(
                alpha: _isDark(context) ? 0.14 : 0.1,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 16, color: item.color),
                const SizedBox(height: 8),
                Text(
                  '${item.value}',
                  style: TextStyle(
                    color: item.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(color: _textMuted(context), fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCompletionRing(BuildContext context, Map<String, dynamic> data) {
    final total = data['totalTasks'] as int? ?? 0;
    final completed = data['completed'] as int? ?? 0;
    final pct = total > 0 ? completed / total : 0.0;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surface(context), _surfaceAlt(context)],
        ),
        border: Border.all(color: _border(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    centerSpaceRadius: 36,
                    sectionsSpace: 2,
                    sections: [
                      PieChartSectionData(
                        value: pct * 100,
                        color: primary,
                        showTitle: false,
                        radius: 12,
                      ),
                      PieChartSectionData(
                        value: (1 - pct) * 100,
                        color: _border(context),
                        showTitle: false,
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _textPrimary(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Progress',
                  style: TextStyle(
                    color: _textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed of $total tasks completed',
                  style: TextStyle(color: _textMuted(context), fontSize: 12),
                ),
                const SizedBox(height: 12),
                _legend(context, 'Completed', pct, primary),
                const SizedBox(height: 6),
                _legend(context, 'Remaining', 1 - pct, _border(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, double pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: _textMuted(context), fontSize: 12)),
        const Spacer(),
        Text(
          '${(pct * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: _textPrimary(context),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    Map<String, int>? completionData,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final weekDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final chartData = List.generate(7, (i) {
      final date = now.subtract(Duration(days: now.weekday - 1 - i));
      final key = '${date.day}-${date.month}-${date.year}';
      return (completionData?[key] ?? 0).toDouble();
    });

    final maxY = chartData.fold(0.0, (a, b) => a > b ? a : b) + 2;
    final todayIdx = now.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surface(context), _surfaceAlt(context)],
        ),
        border: Border.all(color: _border(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Completion',
            style: TextStyle(
              color: _textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tasks completed each day',
            style: TextStyle(color: _textMuted(context), fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (_) => FlLine(color: _border(context), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _textMuted(context),
                            ),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            weekDays[idx],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  idx == todayIdx
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                              color:
                                  idx == todayIdx
                                      ? scheme.primary
                                      : _textMuted(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  final isToday = i == todayIdx;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: chartData[i],
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color:
                            isToday
                                ? scheme.primary
                                : scheme.primary.withValues(
                                  alpha: _isDark(context) ? 0.35 : 0.25,
                                ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: _border(context).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDonut(
    BuildContext context,
    Map<String, int>? categoryData,
  ) {
    if (categoryData == null || categoryData.isEmpty) {
      return const SizedBox();
    }

    final scheme = Theme.of(context).colorScheme;
    final entries = categoryData.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + e.value);

    final palette = [
      scheme.primary,
      const Color(0xFF12B886),
      const Color(0xFFF59F00),
      const Color(0xFFE03131),
      const Color(0xFF0CA678),
      const Color(0xFF1C7ED6),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surface(context), _surfaceAlt(context)],
        ),
        border: Border.all(color: _border(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks by Category',
            style: TextStyle(
              color: _textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total total tasks',
            style: TextStyle(color: _textMuted(context), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 44,
                    sections: List.generate(entries.length, (i) {
                      final entry = entries[i];
                      return PieChartSectionData(
                        value: entry.value.toDouble(),
                        color: palette[i % palette.length],
                        showTitle: false,
                        radius: 26,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final pct =
                        total == 0 ? 0 : ((e.value / total) * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: palette[i % palette.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.key,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textMuted(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              color: _textPrimary(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final rows = [
      (
        label: 'High',
        value: data['highPriority'] as int? ?? 0,
        color: const Color(0xFFE03131),
        icon: Icons.keyboard_double_arrow_up_rounded,
      ),
      (
        label: 'Medium',
        value: data['mediumPriority'] as int? ?? 0,
        color: const Color(0xFFF59F00),
        icon: Icons.drag_handle_rounded,
      ),
      (
        label: 'Low',
        value: data['lowPriority'] as int? ?? 0,
        color: const Color(0xFF12B886),
        icon: Icons.keyboard_double_arrow_down_rounded,
      ),
    ];

    final maxValue = rows.map((r) => r.value).fold(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_surface(context), _surfaceAlt(context)],
        ),
        border: Border.all(color: _border(context)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority Breakdown',
            style: TextStyle(
              color: _textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ...rows.map((row) {
            final ratio = row.value / maxValue;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: row.color.withValues(
                        alpha: _isDark(context) ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(row.icon, size: 16, color: row.color),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 58,
                    child: Text(
                      row.label,
                      style: TextStyle(
                        color: _textMuted(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: _border(context),
                        valueColor: AlwaysStoppedAnimation<Color>(row.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${row.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: row.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
