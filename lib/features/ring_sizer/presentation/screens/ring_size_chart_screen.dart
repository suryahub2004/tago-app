import 'package:flutter/material.dart';
import '../../domain/ring_size_chart.dart';

class RingSizeChartScreen extends StatelessWidget {
  const RingSizeChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Size Chart')),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Note: Ring sizes can vary by brand — always check with the specific ring brand before ordering.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.blueAccent.withValues(alpha: 0.1)),
                  columns: const [
                    DataColumn(label: Text('Inner Ø (mm)')),
                    DataColumn(label: Text('US')),
                    DataColumn(label: Text('EU')),
                    DataColumn(label: Text('UK')),
                    DataColumn(label: Text('JP')),
                    DataColumn(label: Text('IN')),
                  ],
                  rows: ringSizeChart.map((entry) {
                    return DataRow(cells: [
                      DataCell(Text(entry.diameterMm.toString())),
                      DataCell(Text(entry.usSize)),
                      DataCell(Text(entry.euSize)),
                      DataCell(Text(entry.ukSize)),
                      DataCell(Text(entry.jpSize)),
                      DataCell(Text(entry.inSize)),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
