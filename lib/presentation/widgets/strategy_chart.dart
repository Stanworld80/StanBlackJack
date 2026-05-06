import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StrategyChart extends StatelessWidget {
  const StrategyChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('TOTAUX RIGIDES (HARD)'),
            _buildHardTable(),
            const SizedBox(height: 24),
            _buildSectionTitle('TOTAUX SOUPLES (SOFT)'),
            _buildSoftTable(),
            const SizedBox(height: 24),
            _buildSectionTitle('PAIRES (SPLIT)'),
            _buildPairsTable(),
            const SizedBox(height: 24),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHardTable() {
    final rows = [
      ['17+', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S'],
      ['16', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'Sur', 'Sur', 'Sur'],
      ['15', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'Sur', 'H'],
      ['14', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H'],
      ['13', 'S', 'S', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H'],
      ['12', 'H', 'H', 'S', 'S', 'S', 'H', 'H', 'H', 'H', 'H'],
      ['11', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D'],
      ['10', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H', 'H'],
      ['9', 'H', 'D', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H'],
      ['8-', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H', 'H'],
    ];
    return _buildTable(rows);
  }

  Widget _buildSoftTable() {
    final rows = [
      ['A,8+', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S'],
      ['A,7', 'S', 'D', 'D', 'D', 'D', 'S', 'S', 'H', 'H', 'H'],
      ['A,6', 'H', 'D', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H'],
      ['A,5', 'H', 'H', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H'],
      ['A,4', 'H', 'H', 'D', 'D', 'D', 'H', 'H', 'H', 'H', 'H'],
      ['A,3', 'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H', 'H'],
      ['A,2', 'H', 'H', 'H', 'D', 'D', 'H', 'H', 'H', 'H', 'H'],
    ];
    return _buildTable(rows);
  }

  Widget _buildPairsTable() {
    final rows = [
      ['A,A', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
      ['10,10', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S', 'S'],
      ['9,9', 'P', 'P', 'P', 'P', 'P', 'S', 'P', 'P', 'S', 'S'],
      ['8,8', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P', 'P'],
      ['7,7', 'P', 'P', 'P', 'P', 'P', 'P', 'H', 'H', 'H', 'H'],
      ['6,6', 'P', 'P', 'P', 'P', 'P', 'H', 'H', 'H', 'H', 'H'],
      ['5,5', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'H', 'H'],
      ['4,4', 'H', 'H', 'H', 'P', 'P', 'H', 'H', 'H', 'H', 'H'],
      ['3,3', 'P', 'P', 'P', 'P', 'P', 'P', 'H', 'H', 'H', 'H'],
      ['2,2', 'P', 'P', 'P', 'P', 'P', 'P', 'H', 'H', 'H', 'H'],
    ];
    return _buildTable(rows);
  }

  Widget _buildTable(List<List<String>> rows) {
    final dealerHeaders = ['UP', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'A'];

    return Table(
      border: TableBorder.all(color: Colors.white10),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
          children: dealerHeaders.map((h) => _buildCell(h, isHeader: true)).toList(),
        ),
        ...rows.map((row) => TableRow(
          children: row.map((cell) => _buildCell(cell)).toList(),
        )),
      ],
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    Color? bgColor;
    if (!isHeader) {
      if (text == 'S') bgColor = Colors.red.withValues(alpha: 0.3);
      if (text == 'H') bgColor = Colors.green.withValues(alpha: 0.3);
      if (text == 'D') bgColor = Colors.blue.withValues(alpha: 0.3);
      if (text == 'P') bgColor = Colors.purple.withValues(alpha: 0.3);
      if (text == 'Sur') bgColor = Colors.orange.withValues(alpha: 0.3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      color: bgColor,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isHeader ? AppColors.gold : Colors.white,
            fontSize: 10,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('H', 'TIRER', Colors.green),
        _buildLegendItem('S', 'RESTER', Colors.red),
        _buildLegendItem('D', 'DOUBLER', Colors.blue),
        _buildLegendItem('P', 'SÉPARER', Colors.purple),
        _buildLegendItem('Sur', 'ABANDONNER', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(child: Text(code, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
