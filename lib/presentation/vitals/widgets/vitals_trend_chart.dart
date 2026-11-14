import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../data/models/vital_reading_model.dart';

class VitalsTrendChart extends StatefulWidget {
  final List<VitalReadingModel> vitals;

  const VitalsTrendChart({super.key, required this.vitals});

  @override
  State<VitalsTrendChart> createState() => _VitalsTrendChartState();
}

class _VitalsTrendChartState extends State<VitalsTrendChart> {
  int _selectedMetricIndex = 0; // 0: Blood Pressure, 1: Continuous Glucose

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMetricIndex == 0
                            ? '14-Day Hemodynamic BP Profile'
                            : '14-Day CGM Glycemic Trajectory',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _selectedMetricIndex == 0
                            ? 'Systolic (Teal) vs Diastolic (Cyan) mmHg'
                            : 'Sensor Interstitial Glucose (mg/dL)',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('BP', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.favorite_outline_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('CGM', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.water_drop_outlined, size: 14),
                    ),
                  ],
                  selected: {_selectedMetricIndex},
                  onSelectionChanged: (val) {
                    setState(() => _selectedMetricIndex = val.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: _selectedMetricIndex == 0
                  ? _buildBloodPressureChart(context)
                  : _buildGlucoseChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bpVitals = widget.vitals
        .where((v) => v.systolic != null && v.diastolic != null)
        .toList()
        .reversed
        .toList();

    if (bpVitals.isEmpty) {
      return Center(
        child: Text(
          'No historical blood pressure readings recorded.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];

    for (int i = 0; i < bpVitals.length; i++) {
      systolicSpots.add(FlSpot(i.toDouble(), bpVitals[i].systolic!.toDouble()));
      diastolicSpots.add(
        FlSpot(i.toDouble(), bpVitals[i].diastolic!.toDouble()),
      );
    }

    return LineChart(
      LineChartData(
        minY: 50,
        maxY: 160,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withAlpha(80),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 30,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 0),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 0),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 0),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Systolic line
          LineChartBarData(
            spots: systolicSpots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withAlpha(25),
            ),
          ),
          // Diastolic line
          LineChartBarData(
            spots: diastolicSpots,
            isCurved: true,
            color: colorScheme.secondary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.secondary.withAlpha(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final glucoseVitals = widget.vitals
        .where((v) => v.glucoseMgDl != null)
        .toList()
        .reversed
        .toList();

    if (glucoseVitals.isEmpty) {
      return Center(
        child: Text(
          'No historical continuous glucose readings recorded.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < glucoseVitals.length; i++) {
      spots.add(FlSpot(i.toDouble(), glucoseVitals[i].glucoseMgDl!.toDouble()));
    }

    return LineChart(
      LineChartData(
        minY: 60,
        maxY: 200,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 35,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withAlpha(80),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 40,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 0),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 0),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false, reservedSize: 0),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.secondary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.secondary.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }
}
