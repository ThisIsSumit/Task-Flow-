import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        final data = controller.analyticsData;
        if (data.isEmpty) {
          return Center(child: Text('No analytics data available'));
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsCard(data),
              SizedBox(height: 24),
              _buildCompletionChart(data['completionByDay']),
              SizedBox(height: 24),
              _buildCategoryChart(data['tasksByCategory']),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildStatsCard(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', data['totalTasks'] ?? 0),
                _buildStatItem('Completed', data['completed'] ?? 0),
                _buildStatItem('Pending', data['pending'] ?? 0),
                _buildStatItem('Overdue', data['overdue'] ?? 0),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: data['totalTasks'] > 0 
                  ? (data['completed'] / data['totalTasks']) 
                  : 0,
              backgroundColor: Colors.grey[200],
              color: Theme.of(Get.context!).colorScheme.primary,
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              '${data['totalTasks'] > 0 
                  ? ((data['completed'] / data['totalTasks']) * 100).toStringAsFixed(1) 
                  : 0}% completed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
  
  Widget _buildCompletionChart(Map<String, int>? completionData) {
    if (completionData == null || completionData.isEmpty) {
      return SizedBox();
    }
    
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final chartData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: now.weekday - 1 - index));
      final dayKey = '${date.day}-${date.month}-${date.year}';
      return completionData[dayKey] ?? 0;
    });
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Completion',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (chartData.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              weekDays[value.toInt()],
                              style: TextStyle(fontSize: 12),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 12),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: chartData[index].toDouble(),
                          color: Theme.of(Get.context!).colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryChart(Map<String, int>? categoryData) {
    if (categoryData == null || categoryData.isEmpty) {
      return SizedBox();
    }
    
    final entries = categoryData.entries.toList();
    final colors = [
      Theme.of(Get.context!).colorScheme.primary,
      Theme.of(Get.context!).colorScheme.secondary,
      Theme.of(Get.context!).colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      color: colors[index % colors.length],
                      title: '${entry.key}\n${entry.value}',
                      radius: 20,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
