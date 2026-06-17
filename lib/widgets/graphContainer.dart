import 'package:ephysicsapp/screens/Admin/annualAdminAppUsageStatistics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GraphContainer extends StatelessWidget {
  final double maxY;
  final int yInterval;
  final List<BarChartGroupData> Function() getChartData;
  final String title;
  final String selectedYear;
  final int selectedMonthIndex;

  const GraphContainer({
    required this.maxY,
    required this.yInterval,
    required this.getChartData,
    required this.title,
    required this.selectedYear,
    required this.selectedMonthIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 3.25,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        double usageInMinutes = rod.toY;
                        int totalSeconds = (usageInMinutes * 60).round();
                        int hours = (usageInMinutes / 60).round();
                        int minutes = (usageInMinutes - (hours * 60)).round();
                        int seconds = totalSeconds % 60;
                        String tooltipText = '';
                        tooltipText += '$hours hours ';
                        if (minutes > 0) tooltipText += '$minutes min ';
                        tooltipText += '$seconds sec';
                        return BarTooltipItem(
                          tooltipText,
                          TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: 18,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: MediaQuery.of(context).size.width * 0.11,
                        interval: yInterval.toDouble(),
                        getTitlesWidget: (value, meta) => Text(
                          formatYAxisLabel(value),
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Weeks in ${months[selectedMonthIndex]} ${selectedYear}',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(
                          (value + 1).toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    horizontalInterval: yInterval.toDouble(),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.3),
                        strokeWidth: 2,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.3),
                        strokeWidth: 2,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                          color: Colors.black, width: 2), // Left Y-axis
                      bottom: BorderSide(
                          color: Colors.black, width: 2), // Bottom X-axis
                    ),
                  ),
                  barGroups: getChartData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatYAxisLabel(double value) {
    double hours = value / 60; // Convert minutes to hours

    if (hours >= 1000) {
      return '${(hours / 1000).toStringAsFixed(1)}K H'; // Example: 1800 → 1.8K H
    } else if (hours >= 100) {
      return '${hours.round()} H'; // Example: 458.5 → 459H (No decimals)
    } else if (hours >= 1) {
      return '${hours.toStringAsFixed(1)} H'; // Example: 90 → 1.5H
    } else {
      return '${value.toInt()} H'; // Example: 45 → 45M
    }
  }
}
